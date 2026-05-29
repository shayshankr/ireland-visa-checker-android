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


def _extract_rows_from_text(text: str, source_label: str) -> list[dict]:
    """Parse application numbers and decisions from plain text."""
    rows_out = []
    for line in text.split("\n"):
        parts = line.split()
        for i, part in enumerate(parts):
            if not re.match(r"^\d{8}$", part):
                continue
            decision = ""
            for j in range(i + 1, min(i + 4, len(parts))):
                w = parts[j].upper()
                if "APPROV" in w:
                    decision = "APPROVED"
                    break
                if "REFUS" in w:
                    decision = "REFUSED"
                    break
            if decision:
                rows_out.append({
                    "application_number": part,
                    "decision": decision,
                    "source": source_label,
                })
    return rows_out


def _parse_pdf(content: bytes, source_label: str) -> pd.DataFrame:
    rows_out = []

    # ── Attempt 1: pdfplumber text extraction (text-based PDFs) ──────────────
    try:
        import pdfplumber  # type: ignore
        with pdfplumber.open(io.BytesIO(content)) as pdf:
            for page in pdf.pages:
                text = page.extract_text() or ""
                rows_out.extend(_extract_rows_from_text(text, source_label))
    except Exception:
        pass

    if rows_out:
        return pd.DataFrame(rows_out)

    # ── Attempt 2: pytesseract OCR (scanned/image PDFs) ──────────────────────
    try:
        import fitz          # type: ignore  (PyMuPDF)
        import pytesseract   # type: ignore
        from PIL import Image
        import numpy as np

        doc = fitz.open(stream=content, filetype="pdf")
        for page in doc:
            mat = fitz.Matrix(2.0, 2.0)
            pix = page.get_pixmap(matrix=mat, colorspace=fitz.csRGB)
            img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
            text = pytesseract.image_to_string(img, config="--psm 6")
            rows_out.extend(_extract_rows_from_text(text, source_label))
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
    # Only fetch the most recent file (first link on the page)
    for link in links[:1]:
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
        except Exception:
            continue

    if frames:
        combined = pd.concat(frames, ignore_index=True)
        combined = combined.drop_duplicates(subset=["application_number"], keep="last")
        save_to_disk(name, combined, first_url, etag, last_modified)
        return combined, "fresh"

    if df is not None:
        return df, "stale_cache"
    return pd.DataFrame(), "no_data"
