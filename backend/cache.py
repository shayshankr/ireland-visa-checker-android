import os
import json
import pickle
import hashlib
import time

import requests

CACHE_DIR = os.path.join(os.path.dirname(__file__), ".cache_v2")
MAX_AGE_HOURS = 24

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    ),
    "Referer": "https://www.ireland.ie/",
    "Accept": "application/pdf,application/octet-stream,*/*",
}


def _cache_key(name: str) -> str:
    return hashlib.md5(name.encode()).hexdigest()


def load_from_disk(name: str):
    key = _cache_key(name)
    meta_path = os.path.join(CACHE_DIR, f"{key}.json")
    data_path = os.path.join(CACHE_DIR, f"{key}.pkl")
    if not os.path.exists(meta_path) or not os.path.exists(data_path):
        return None, None
    with open(meta_path) as f:
        meta = json.load(f)
    with open(data_path, "rb") as f:
        df = pickle.load(f)
    return df, meta


def save_to_disk(name: str, df, url: str, etag: str = None, last_modified: str = None):
    os.makedirs(CACHE_DIR, exist_ok=True)
    key = _cache_key(name)
    meta = {
        "timestamp": time.time(),
        "url": url,
        "etag": etag,
        "last_modified": last_modified,
    }
    with open(os.path.join(CACHE_DIR, f"{key}.json"), "w") as f:
        json.dump(meta, f)
    with open(os.path.join(CACHE_DIR, f"{key}.pkl"), "wb") as f:
        pickle.dump(df, f)


def is_cache_fresh(meta: dict) -> bool:
    age = time.time() - meta.get("timestamp", 0)
    return age < MAX_AGE_HOURS * 3600


def check_etag(url: str):
    try:
        r = requests.head(url, headers=HEADERS, timeout=10)
        return r.headers.get("ETag"), r.headers.get("Last-Modified")
    except Exception:
        return None, None


def etag_unchanged(meta: dict, etag: str, last_modified: str) -> bool:
    if etag and meta.get("etag") == etag:
        return True
    if last_modified and meta.get("last_modified") == last_modified:
        return True
    return False


def clear_cache(name: str = None) -> int:
    """
    Delete cached files from disk.
    If name is given, clears only that embassy.
    If name is None, clears ALL embassy caches.
    Returns number of files deleted.
    """
    import glob
    deleted = 0
    if name:
        key = _cache_key(name)
        for ext in (".json", ".pkl"):
            path = os.path.join(CACHE_DIR, f"{key}{ext}")
            if os.path.exists(path):
                os.remove(path)
                deleted += 1
    else:
        for path in glob.glob(os.path.join(CACHE_DIR, "*.json")) + \
                    glob.glob(os.path.join(CACHE_DIR, "*.pkl")):
            os.remove(path)
            deleted += 1
    return deleted
