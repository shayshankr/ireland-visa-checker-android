import re
from concurrent.futures import ThreadPoolExecutor

import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from embassies import EMBASSIES
from fetchers import fetch_embassy

app = FastAPI(title="Ireland Visa Checker API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory store: { embassy_name: { "df": DataFrame, "source": str, "embassy": dict } }
_store: dict = {}


def _load_all() -> None:
    with ThreadPoolExecutor(max_workers=5) as ex:
        futures = {ex.submit(fetch_embassy, e): e for e in EMBASSIES}
        for future, embassy in futures.items():
            try:
                df, source = future.result()
            except Exception:
                df, source = pd.DataFrame(), "error"
            _store[embassy["name"]] = {"df": df, "source": source, "embassy": embassy}


@app.on_event("startup")
async def startup() -> None:
    _load_all()


# ── Health ────────────────────────────────────────────────────────────────────

@app.get("/api/health")
def health():
    return {"status": "ok"}


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
    stripped = re.sub(r"^[Ii][Rr][Ll]\d*", "", raw.strip())
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


# ── Manual refresh ────────────────────────────────────────────────────────────

@app.post("/api/refresh")
def refresh():
    _load_all()
    return {"status": "refreshed"}
