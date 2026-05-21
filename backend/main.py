import re
import logging
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime

import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from apscheduler.schedulers.background import BackgroundScheduler

from embassies import EMBASSIES
from fetchers import fetch_embassy, _find_file_links

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Ireland Visa Checker API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory store: { embassy_name: { "df": DataFrame, "source": str, "embassy": dict } }
_store: dict = {}
_last_refreshed: dict = {}   # { embassy_name: "YYYY-MM-DD HH:MM UTC" }


def _load_one(embassy: dict) -> None:
    """Refresh a single embassy and update the store."""
    name = embassy["name"]
    try:
        df, source = fetch_embassy(embassy)
    except Exception:
        df, source = pd.DataFrame(), "error"
    _store[name] = {"df": df, "source": source, "embassy": embassy}
    _last_refreshed[name] = datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")
    logger.info(f"[{name}] refreshed — {len(df)} records at {_last_refreshed[name]}")


def _load_newdelhi() -> None:
    """Refresh New Delhi only (called every 5 min)."""
    embassy = next(e for e in EMBASSIES if e["name"] == "New Delhi")
    _load_one(embassy)


def _load_all() -> None:
    """Refresh all 5 embassies in parallel (called every 15 min)."""
    logger.info("Refreshing all embassies...")
    with ThreadPoolExecutor(max_workers=5) as ex:
        futures = {ex.submit(_load_one, e): e for e in EMBASSIES}
        for future in futures:
            try:
                future.result()
            except Exception as exc:
                logger.error(f"Error refreshing embassy: {exc}")


@app.on_event("startup")
async def startup() -> None:
    # Initial load
    _load_all()

    # ── Scheduler ─────────────────────────────────────────────────────────────
    # New Delhi  → every 5 min  (daily publish, results can come any time)
    # All others → every 15 min (Beijing daily, rest weekly)
    scheduler = BackgroundScheduler(timezone="UTC")
    scheduler.add_job(_load_newdelhi, "interval", minutes=5,  id="newdelhi_5min")
    scheduler.add_job(_load_all,      "interval", minutes=15, id="all_15min")
    scheduler.start()
    logger.info("Scheduler started: New Delhi every 5 min | all embassies every 15 min.")


# ── Health ────────────────────────────────────────────────────────────────────

@app.get("/api/health")
def health():
    return {
        "status": "ok",
        "last_refreshed": _last_refreshed,          # per-embassy timestamps
        "record_counts": {k: len(v["df"]) for k, v in _store.items()},
        "schedule": {
            "New Delhi": "every 5 min",
            "Beijing": "every 15 min",
            "Abuja": "every 15 min",
            "Abu Dhabi": "every 15 min",
            "Ankara": "every 15 min",
        }
    }


# ── Embassies ─────────────────────────────────────────────────────────────────

@app.get("/api/embassies")
def get_embassies():
    return [
        {
            "name": name,
            "cadence": data["embassy"]["cadence"],
            "record_count": len(data["df"]),
            "source": data["source"],
            "available": not data["df"].empty,
        }
        for name, data in _store.items()
    ]


# ── Stats ─────────────────────────────────────────────────────────────────────

@app.get("/api/stats")
def get_stats():
    total = approved = refused = 0
    for data in _store.values():
        df: pd.DataFrame = data["df"]
        if df.empty:
            continue
        total += len(df)
        approved += int((df["decision"].str.upper() == "APPROVED").sum())
        refused += int((df["decision"].str.upper() == "REFUSED").sum())
    return {"total": total, "approved": approved, "refused": refused}


# ── Check application ─────────────────────────────────────────────────────────

class CheckRequest(BaseModel):
    application_number: str


def _normalize(raw: str) -> str:
    """Strip optional IRL prefix and non-digits, require exactly 8 digits."""
    stripped = re.sub(r"^[Ii][Rr][Ll]", "", raw.strip())
    digits = re.sub(r"\D", "", stripped)
    return digits


@app.post("/api/check")
def check_application(req: CheckRequest):
    num = _normalize(req.application_number)
    if not re.match(r"^\d{8}$", num):
        raise HTTPException(status_code=400, detail="Application number must be 8 digits (e.g. 63690452)")

    results = []
    all_numbers: list[str] = []

    for name, data in _store.items():
        df: pd.DataFrame = data["df"]
        if df.empty:
            continue
        all_numbers.extend(df["application_number"].tolist())
        match = df[df["application_number"] == num]
        if not match.empty:
            row = match.iloc[0]
            results.append(
                {
                    "embassy": name,
                    "decision": row.get("decision", ""),
                    "source": row.get("source", ""),
                }
            )

    if results:
        return {"application_number": num, "found": True, "results": results, "nearest": None}

    # Not found — return neighbouring application numbers as context
    sorted_nums = sorted(set(all_numbers))
    before = [n for n in sorted_nums if n < num]
    after = [n for n in sorted_nums if n > num]

    nearest: dict = {}

    def _find_row(target: str) -> dict | None:
        for name, data in _store.items():
            df: pd.DataFrame = data["df"]
            if df.empty:
                continue
            m = df[df["application_number"] == target]
            if not m.empty:
                row = m.iloc[0]
                return {
                    "number": target,
                    "embassy": name,
                    "decision": row.get("decision", ""),
                    "difference": abs(int(num) - int(target)),
                }
        return None

    if before:
        entry = _find_row(before[-1])
        if entry:
            nearest["before"] = entry
    if after:
        entry = _find_row(after[0])
        if entry:
            nearest["after"] = entry

    return {"application_number": num, "found": False, "results": [], "nearest": nearest or None}


# ── Debug: show what links are found on each embassy page ────────────────────

@app.get("/api/debug/ods/{embassy_name}")
def debug_ods(embassy_name: str):
    import io, requests
    from cache import HEADERS
    embassy = next((e for e in EMBASSIES if e["name"].lower() == embassy_name.lower()), None)
    if not embassy:
        raise HTTPException(status_code=404, detail="Embassy not found")
    links = _find_file_links(embassy["url"], embassy["keyword"], embassy["file_type"])
    if not links:
        return {"error": "no links found"}
    r = requests.get(links[0]["url"], headers=HEADERS, timeout=30)
    try:
        import pyexcel_ods3
        data = pyexcel_ods3.get_data(io.BytesIO(r.content))
        preview = {}
        first_data_row = None
        for sheet, rows in data.items():
            preview[sheet] = rows[:20]
            for i, row in enumerate(rows):
                for cell in row:
                    if re.match(r"^\d{8}$", str(cell).strip()):
                        first_data_row = {"row_index": i, "row": row}
                        break
                if first_data_row:
                    break
        return {"url": links[0]["url"], "sheets": list(data.keys()), "first_data_row": first_data_row, "preview": preview}
    except Exception as e:
        return {"error": str(e)}


@app.get("/api/debug/links")
def debug_links():
    results = {}
    for embassy in EMBASSIES:
        try:
            links = _find_file_links(embassy["url"], embassy["keyword"], embassy["file_type"])
            results[embassy["name"]] = {"found": len(links), "links": links}
        except Exception as e:
            results[embassy["name"]] = {"found": 0, "error": str(e)}
    return results


# ── Manual refresh ────────────────────────────────────────────────────────────

@app.post("/api/refresh")
def refresh():
    _load_all()
    return {"status": "refreshed", "last_refreshed": _last_refreshed}
