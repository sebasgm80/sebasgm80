import json
import os
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Literal, Optional

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field
from dotenv import load_dotenv

from pipeline import (
    pipeline_state, logs, log, read_json, write_json,
    DATA_DIR, NEWS_RAW_PATH, NEWS_CURATED_PATH, POSTS_PATH,
)
from pipeline.scraper import scrape_all
from pipeline.curator import curate
from pipeline.generator import generate_posts

load_dotenv()

# --- Pydantic Models ---

class PipelineConfig(BaseModel):
    top_n: int = Field(default=5, ge=3, le=20)
    platforms: list[Literal["x", "linkedin", "threads"]] = ["x", "linkedin", "threads"]

class SourcesConfig(BaseModel):
    subreddits: list[str]
    rss_feeds: list[str]
    hn_keywords: list[str]

# --- Startup ---

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    DATA_DIR.mkdir(exist_ok=True)
    
    gemini_key = os.getenv("GEMINI_API_KEY", "")
    if gemini_key:
        log("info", f"Gemini API key loaded: ...{gemini_key[-4:]}")
    else:
        log("warning", "GEMINI_API_KEY no configurada — endpoints LLM devolverán 503")
    
    log("info", "data/ verificado")
    yield

app = FastAPI(lifespan=lifespan, title="TrendPulse")

# --- Helpers ---

def _check_not_running():
    if pipeline_state["running"]:
        raise HTTPException(409, "Pipeline ya en curso")

def _check_gemini_key():
    if not os.getenv("GEMINI_API_KEY"):
        raise HTTPException(503, "GEMINI_API_KEY no configurada en .env")

def _load_sources() -> dict:
    try:
        with open("sources.json") as f:
            data = json.load(f)
        # Validate
        SourcesConfig(**data)
        return data
    except Exception as e:
        raise HTTPException(422, detail=f"Error en sources.json: {e}")

def _reset_state(step: str = None):
    pipeline_state["running"] = True
    pipeline_state["step"] = step
    pipeline_state["progress"] = None
    pipeline_state["started_at"] = None
    pipeline_state["finished_at"] = None
    pipeline_state["error"] = None
    pipeline_state["warning"] = None

# --- Background Tasks ---

async def _run_scrape():
    try:
        _reset_state("scrape")
        from datetime import datetime, timezone
        pipeline_state["started_at"] = datetime.now(timezone.utc).isoformat()
        
        sources = _load_sources()
        items = await scrape_all(sources)
        write_json(NEWS_RAW_PATH, items)
        
        pipeline_state["progress"] = f"{len(items)} items"
        log("info", f"Scrape done: {len(items)} items")
    except Exception as e:
        pipeline_state["error"] = str(e)
        log("error", f"Scrape failed: {e}")
    finally:
        pipeline_state["running"] = False
        pipeline_state["step"] = "done"
        from datetime import datetime, timezone
        pipeline_state["finished_at"] = datetime.now(timezone.utc).isoformat()

async def _run_curate(top_n: int):
    try:
        _reset_state("curate")
        from datetime import datetime, timezone
        pipeline_state["started_at"] = datetime.now(timezone.utc).isoformat()
        
        _check_gemini_key()
        items = read_json(NEWS_RAW_PATH, default=[])
        if not items:
            pipeline_state["warning"] = "No hay noticias sin curar. Ejecuta scrape primero."
            pipeline_state["running"] = False
            return
        
        curated, warning = await curate(items, top_n)
        write_json(NEWS_CURATED_PATH, curated)
        pipeline_state["progress"] = f"{len(curated)} items"
        if warning:
            pipeline_state["warning"] = warning
        log("info", f"Curate done: {len(curated)} items")
    except HTTPException:
        pipeline_state["running"] = False
        raise
    except Exception as e:
        pipeline_state["error"] = str(e)
        log("error", f"Curate failed: {e}")
    finally:
        pipeline_state["running"] = False
        pipeline_state["step"] = "done"
        from datetime import datetime, timezone
        pipeline_state["finished_at"] = datetime.now(timezone.utc).isoformat()

async def _run_generate(top_n: int, platforms: list[str]):
    try:
        _reset_state("generate")
        from datetime import datetime, timezone
        pipeline_state["started_at"] = datetime.now(timezone.utc).isoformat()
        
        _check_gemini_key()
        curated = read_json(NEWS_CURATED_PATH, default=[])
        if not curated:
            pipeline_state["warning"] = "No hay noticias curadas. Ejecuta curate primero."
            pipeline_state["running"] = False
            return
        
        posts, warning = await generate_posts(curated, platforms)
        write_json(POSTS_PATH, posts)
        pipeline_state["progress"] = f"{len(posts)} posts"
        if warning:
            pipeline_state["warning"] = warning
        log("info", f"Generate done: {len(posts)} posts")
    except HTTPException:
        pipeline_state["running"] = False
        raise
    except Exception as e:
        pipeline_state["error"] = str(e)
        log("error", f"Generate failed: {e}")
    finally:
        pipeline_state["running"] = False
        pipeline_state["step"] = "done"
        from datetime import datetime, timezone
        pipeline_state["finished_at"] = datetime.now(timezone.utc).isoformat()

async def _run_all(top_n: int, platforms: list[str]):
    try:
        _reset_state("run-all")
        from datetime import datetime, timezone
        pipeline_state["started_at"] = datetime.now(timezone.utc).isoformat()
        
        sources = _load_sources()
        items = await scrape_all(sources)
        write_json(NEWS_RAW_PATH, items)
        pipeline_state["progress"] = f"scrape: {len(items)} items"
        log("info", f"Scrape done: {len(items)} items")
        
        if not items:
            pipeline_state["warning"] = "Scrape devolvió 0 items. Pipeline detenido."
            pipeline_state["running"] = False
            return
        
        _check_gemini_key()
        pipeline_state["step"] = "curate"
        curated, warning = await curate(items, top_n)
        write_json(NEWS_CURATED_PATH, curated)
        pipeline_state["progress"] = f"curate: {len(curated)} items"
        log("info", f"Curate done: {len(curated)} items")
        
        if not curated:
            pipeline_state["warning"] = "Curate devolvió 0 items. Pipeline detenido."
            pipeline_state["running"] = False
            return
        
        pipeline_state["step"] = "generate"
        posts, gen_warning = await generate_posts(curated, platforms)
        write_json(POSTS_PATH, posts)
        pipeline_state["progress"] = f"generate: {len(posts)} posts"
        log("info", f"Generate done: {len(posts)} posts")
        
        pipeline_state["progress"] = f"✅ {len(items)} noticias → {len(posts)} posts"
        log("info", f"Pipeline completado: {len(items)} noticias → {len(posts)} posts")
    except HTTPException:
        pipeline_state["running"] = False
        raise
    except Exception as e:
        pipeline_state["error"] = str(e)
        log("error", f"Pipeline failed: {e}")
    finally:
        pipeline_state["running"] = False
        pipeline_state["step"] = "done"
        from datetime import datetime, timezone
        pipeline_state["finished_at"] = datetime.now(timezone.utc).isoformat()

# --- API Routes ---

@app.get("/api/health")
async def health():
    return {"status": "ok"}

@app.get("/api/sources")
async def get_sources():
    return _load_sources()

@app.get("/api/pipeline/status")
async def get_status():
    return pipeline_state

@app.get("/api/logs")
async def get_logs():
    return list(logs)

@app.get("/api/news")
async def get_news():
    items = read_json(NEWS_CURATED_PATH, default=[])
    if not items:
        return {"items": [], "warning": "Sin noticias curadas. Ejecuta el pipeline."}
    return {"items": items}

@app.get("/api/posts")
async def get_posts():
    items = read_json(POSTS_PATH, default=[])
    return {"items": items}

@app.post("/api/pipeline/scrape")
async def trigger_scrape(background_tasks: BackgroundTasks):
    _check_not_running()
    background_tasks.add_task(_run_scrape)
    return {"task_started": True, "step": "scrape"}

@app.post("/api/pipeline/curate")
async def trigger_curate(config: PipelineConfig, background_tasks: BackgroundTasks):
    _check_not_running()
    background_tasks.add_task(_run_curate, config.top_n)
    return {"task_started": True, "step": "curate", "top_n": config.top_n}

@app.post("/api/pipeline/generate")
async def trigger_generate(config: PipelineConfig, background_tasks: BackgroundTasks):
    _check_not_running()
    background_tasks.add_task(_run_generate, config.top_n, config.platforms)
    return {"task_started": True, "step": "generate", "top_n": config.top_n, "platforms": config.platforms}

@app.post("/api/pipeline/run-all")
async def trigger_run_all(config: PipelineConfig, background_tasks: BackgroundTasks):
    _check_not_running()
    background_tasks.add_task(_run_all, config.top_n, config.platforms)
    return {"task_started": True, "step": "run-all", "top_n": config.top_n, "platforms": config.platforms}

# --- Static Files ---

app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/")
async def index():
    return FileResponse("static/index.html")
