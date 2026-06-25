from collections import deque
from datetime import datetime, timezone
from pathlib import Path
import json
import os

DATA_DIR = Path("./data")
SEEN_URLS_PATH = DATA_DIR / "seen_urls.json"
NEWS_RAW_PATH = DATA_DIR / "news_raw.json"
NEWS_CURATED_PATH = DATA_DIR / "news_curated.json"
POSTS_PATH = DATA_DIR / "posts.json"
LLM_LOG_PATH = DATA_DIR / "llm_calls.jsonl"

# In-memory pipeline state
pipeline_state: dict = {
    "running": False,
    "step": None,
    "progress": None,
    "started_at": None,
    "finished_at": None,
    "error": None,
    "warning": None,
}

# Circular buffer for UI polling
logs: deque = deque(maxlen=200)


def log(level: str, msg: str) -> None:
    entry = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "level": level,
        "msg": msg,
    }
    logs.append(entry)
    print(f"[{level.upper()}] {msg}")


def read_json(path: Path, default=None):
    path = Path(path) if not isinstance(path, Path) else path
    if not path.exists():
        return [] if default is None else default
    with open(path) as f:
        return json.load(f)


def write_json(path: Path, data) -> None:
    path = Path(path) if not isinstance(path, Path) else path
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with open(tmp, "w") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    os.replace(tmp, path)


def add_seen_url(url: str) -> None:
    urls = read_json(SEEN_URLS_PATH, default=[])
    if url not in urls:
        urls.append(url)
    urls = urls[-1000:]  # cap at 1000
    write_json(SEEN_URLS_PATH, urls)


def is_seen(url: str) -> bool:
    urls: list = read_json(SEEN_URLS_PATH, default=[])
    return url in urls


def log_llm_call(step: str, tokens_in: int, tokens_out: int, latency_s: float) -> None:
    entry = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "step": step,
        "tokens_in": tokens_in,
        "tokens_out": tokens_out,
        "latency_s": round(latency_s, 2),
    }
    log("info", f"[gemini] step={step} tokens_in={tokens_in} tokens_out={tokens_out} latency={latency_s:.1f}s")
    try:
        with open(LLM_LOG_PATH, "a") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    except OSError:
        pass
