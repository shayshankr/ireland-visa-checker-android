import io
import re
import time

import requests
import pandas as pd
from bs4 import BeautifulSoup

from cache import (
    HEADERS,
    check_etag,
    etag_unchanged,
    is_cache_fresh,
    load_from_disk,
    save_to_disk,
)

MAX_RETRIES = 3


def _get_with_retry(url: str, stream: bool = False) -> requests.Response:
    for attempt in range(MAX_RETRIES):
        try:
            r = requests.get(url, headers=HEADERS, timeout=30, stream=stream)
            r.raise_for_status()
            return r
        except (requests.Timeout, requests.ConnectionError):
            if attempt == MAX_RETRIES - 1:
                raise
            time.sleep(2**attempt)
    raise RuntimeError("unreachable")


def _find_file_links(page_url: str, keyword: str, ext: str) -> list[dict]:
    r = _get_with_retry(page_url)
    soup = BeautifulSoup(r.text, "html.parser")
    results = []
    for a in soup.find_all("a", href=True):
        href: str = a["href"]
        label: str = a.get_text(strip=True) or href
        if ext in href.lower() and keyword.lower() in label.lower():
            if href.startswith("/"):
                href = "https://www.ireland.ie" + href
            results.append({"label": label, "url": href})
    return results


def _parse_ods(content: bytes, source_label: str) -> pd.DataFrame:
    try:
        import pyexcel_ods3  # type: ignore

        data = pyexcel_ods3.get_data(io.BytesIO(content))
        rows_out = []
        for rows in data.values():
            for row in rows:
                # Data is in columns 2 (app number as int) and 3 (decision)
                if len(row) < 4:
                    continue
                app_num = str(row[2]).strip()
                decision = str(row[3]).strip().upper()
                if re.match(r"^\d{8}$", app_num) and decision in ("APPROVED", "REFUSED"):
                    rows_out.append(
                        {
                            "application_number": app_num,
                            "decision": decision,
                            "source": source_label,
                        }
                    )
        return pd.DataFrame(rows_out) if rows_out else pd.DataFrame()
    except Exception:
        return pd.DataFrame()


def _parse_pdf(content: bytes, source_label: str) -> pd.DataFrame:
    rows_out = []

    # ── Attempt 1: pdfplumber text extraction ─────────────────────────────────
    try:
        import pdfplumber  # type: ignore

        with pdfplumber.open(io.BytesIO(content)) as pdf:
            for page in pdf.pages:
                for table in page.extract_tables():
                    for row in table:
                        if not row or len(row) < 2:
                            continue
                        app_num = str(row[0]).strip() if row[0] else ""
                        decision = str(row[1]).strip().upper() if row[1] else ""
                        if not re.match(r"^\d{7,9}$", app_num):
                            continue
                        if "APPROV" in decision:
                            decision = "APPROVED"
                        elif "REFUS" in decision:
                            decision = "REFUSED"
                        else:
                            continue
                        rows_out.append({
                            "application_number": app_num,
                            "decision": decision,
                            "source": source_label,
                        })
    except Exception:
        pass

    if rows_out:
        return pd.DataFrame(rows_out)

    # ── Attempt 2: easyocr fallback for scanned/image PDFs ───────────────────
    try:
        import fitz        # type: ignore  (PyMuPDF)
        import easyocr     # type: ignore
        import numpy as np

        reader = easyocr.Reader(['en'], gpu=False, verbose=False)
        doc = fitz.open(stream=content, filetype="pdf")
        for page in doc:
            mat = fitz.Matrix(2.0, 2.0)
            pix = page.get_pixmap(matrix=mat, colorspace=fitz.csRGB)
            img_array = np.frombuffer(pix.samples, dtype=np.uint8).reshape(pix.height, pix.width, 3)
            results = reader.readtext(img_array, detail=0, paragraph=False)
            texts = [t.strip() for t in results]
            for i, text in enumerate(texts):
                if re.match(r"^\d{7,9}$", text) and i + 1 < len(texts):
                    raw_decision = texts[i + 1].strip().upper()
                    if "APPROV" in raw_decision:
                        decision = "APPROVED"
                    elif "REFUS" in raw_decision:
                        decision = "REFUSED"
                    else:
                        continue
                    rows_out.append({
                        "application_number": text,
                        "decision": decision,
                        "source": source_label,
                    })
    except Exception:
        pass

    return pd.DataFrame(rows_out) if rows_out else pd.DataFrame()


def fetch_embassy(embassy: dict) -> tuple[pd.DataFrame, str]:
    name = embassy["name"]
    df, meta = load_from_disk(name)

    try:
        links = _find_file_links(embassy["url"], embassy["keyword"], embassy["file_type"])
    except Exception:
        if df is not None:
            return df, "stale_cache"
        return pd.DataFrame(), "no_data"

    if not links:
        if df is not None:
            return df, "stale_cache"
        return pd.DataFrame(), "no_data"

    first_url = links[0]["url"]

    if df is not None and meta is not None:
        if is_cache_fresh(meta) and meta.get("url") == first_url:
            return df, "disk_cache"

        etag, last_modified = check_etag(first_url)
        if etag_unchanged(meta, etag, last_modified):
            save_to_disk(name, df, first_url, etag, last_modified)
            return df, "etag_cache"

    etag = last_modified = None
    frames = []
    parsed_url = first_url  # fallback; updated to the URL we actually parsed
    # For ODS embassies only fetch first link; for PDF try all until one parses
    links_to_try = links[:1] if embassy["file_type"] == "ods" else links
    for link in links_to_try:
        try:
            r = _get_with_retry(link["url"], stream=True)
            content = r.content
            etag = r.headers.get("ETag")
            last_modified = r.headers.get("Last-Modified")
            frame = (
                _parse_ods(content, link["label"])
                if embassy["file_type"] == "ods"
                else _parse_pdf(content, link["label"])
            )
            if not frame.empty:
                frames.append(frame)
                parsed_url = link["url"]  # record the URL we actually parsed
                break  # stop at first successful parse
        except Exception:
            continue

    if frames:
        combined = pd.concat(frames, ignore_index=True)
        combined = combined.drop_duplicates(subset=["application_number"], keep="last")
        save_to_disk(name, combined, parsed_url, etag, last_modified)
        return combined, "fresh"

    if df is not None:
        return df, "stale_cache"
    return pd.DataFrame(), "no_data"
