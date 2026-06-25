# Fase 1 — Pipeline Agentic de Contenido Corto (trend-pulse)

## TL;DR

> **Quick Summary**: Pipeline end-to-end agentic en FastAPI + vanilla JS. Scrapea noticias de IA (Reddit + HN + RSS), las curan con Gemini 2.0 Flash, genera posts cortos en español para X/LinkedIn/Threads. Dashboard con sliders configurables, run en background, logs y vista de posts con botón copiar.
>
> **Deliverables**:
> - Backend FastAPI con endpoints `/api/pipeline/*` (scrape, curate, generate, run-all, status) + datos (`/api/news`, `/api/posts`, `/api/logs`, `/api/sources`)
> - Pipeline modular (`scraper`, `curator`, `generator`) con dedup persistente y rate-limit handling
> - Dashboard 3-columnas en HTML/CSS/JS plano con sliders, checkboxes, log streaming (polling 2s) y copy-to-clipboard
> - Smoke tests pytest + integración end-to-end + Playwright UI test
> - README Quickstart + `.env.example` con links a providers
>
> **Estimated Effort**: Medium (~600-800 LOC backend + ~300 LOC frontend + tests)
> **Parallel Execution**: YES — 3 waves de implementación + 1 wave final de verificación
> **Critical Path**: Wave 1 foundation → Wave 2 módulos pipeline → Wave 3 integración + UI → Final QA → user okay

---

## Context

### Original Request
> "necesito crear esto poco a poco y por fases, crea el plan solo de la primera fase"
> "la idea es crear un dashboard para controlar un flujo de trabajo agéntico para crear contenido en redes sociales y newsletter, el enfoque es capturar noticias de IA más relevantes y generar algo de contenido corto para consumo rápido y esa es la fase 1, lo ideal es que sea todo agéntico, un agente de IA pueda hacer todo y en un futuro controlar las métricas para adaptarse"

**Reinterpretación crítica**: La "Fase 1" del usuario NO coincide con la Fase 1 literal del README (motor de cableado sin IA). Su Fase 1 conceptual es el pipeline agentic end-to-end con generación de contenido corto desde el inicio.

### Interview Summary
**Decisiones locked en entrevista**:
- **Output**: solo texto, posts cortos (X / LinkedIn / Threads)
- **Nivel agentic**: pipeline fijo + LLM en cada paso (NO chat con tools dinámicos)
- **LLM**: Gemini 2.0 Flash (Google AI Studio free tier, sin tarjeta)
- **Fuentes**: Reddit API OAuth + Hacker News API + RSS (descartados X y Meta por free tier inservible)
- **Volumen**: configurable vía UI (sliders + checkboxes)
- **Idioma**: solo español
- **Storage**: JSON files (sin DB)
- **Frontend**: HTML/CSS/JS plano (sin Tailwind, sin Node, sin build)
- **Tests**: smoke tests pytest

### Research Findings
- Free tier Gemini 2.0 Flash: ~15 RPM / ~1500 RPD / 1M tokens contexto / SDK `google-generativeai` maduro / function calling soportado (no usado en Fase 1) / sin credit card
- Reddit API: free OAuth 60 req/min, subreddits IA accesibles, expiración token 1h, User-Agent estricto
- Hacker News API: Firebase REST sin auth, `/topstories.json` devuelve ~500 IDs, filtrar por keyword en title
- X/Twitter API v2 free: 1500 reads/mes (descartado)
- Meta/Threads: requiere business verification (descartado)

### Metis Review
**Concerns resueltos** (todas validadas con enfoque lazy):
- Idempotencia: `data/seen_urls.json` capado a 1000 URLs (sin hash, la URL es la key)
- Rate limit Gemini: `asyncio.sleep(4.1)` + backoff exponencial (1s/2s/4s, 3 retries), skip-and-continue
- Reddit OAuth: token one-shot por run (no caché)
- Filtrado HN: `keyword.lower() in title.lower()` substring puro
- Storage: atomic writes (`.tmp` → `os.replace`), sobrescribir por run
- Concurrencia: guard `if pipeline_state["running"]` → 409
- Empty results: cada paso valida input no-vacío, 200 con warning si vacío
- JSON malformado de Gemini: try/except + strip backticks + descartar item
- Límites caracteres: X=280, LinkedIn=3000, Threads=500 (truncar + warning)
- Rehidratación: front fetcha `/api/pipeline/status` + `/api/logs` al cargar
- API keys: `.gitignore` + log de últimos 4 chars al arrancar
- LLM logging: tokens en stdout + deque + opcional jsonl

**Recortes estructurales aplicados** (anti-slop):
- ❌ `pipeline/storage.py` eliminado → helpers en `pipeline/__init__.py`
- ❌ `tests/__init__.py` no se crea
- ❌ No langchain, no praw, no loguru, no pydantic-settings

---

## Work Objectives

### Core Objective
Entregar un dashboard funcional end-to-end donde el usuario puede ejecutar un pipeline agentic completo (scrape → curate → generate) con configuración vía UI, ver logs en tiempo real, y copiar posts generados a redes sociales.

### Concrete Deliverables
- `app.py` — FastAPI app con 11 endpoints (4 datos + 4 pipeline + status + sources + health + index)
- `pipeline/scraper.py` — async scraping Reddit + HN + RSS con dedup
- `pipeline/curator.py` — Gemini ranking + summary con JSON mode
- `pipeline/generator.py` — Gemini post generation por plataforma con límites de caracteres
- `pipeline/__init__.py` — helpers `read_json`/`write_json` (atomic) + globals (`pipeline_state`, deque de logs)
- `static/index.html` + `static/styles.css` + `static/app.js` — dashboard 3-columnas funcional
- `sources.json` — defaults para subreddits, RSS feeds, keywords HN
- `tests/test_api.py` — ≥5 smoke tests de endpoints + failure modes
- `tests/test_dashboard.py` — Playwright tests de UI
- `requirements.txt` con versiones pineadas
- `.env.example` con links a Google AI Studio y Reddit apps
- `.gitignore` (`.env`, `data/`, `__pycache__`, `.venv`)
- README sección "Quickstart" en español

### Definition of Done
- [ ] `pytest tests/` pasa con todos los smoke tests verdes
- [ ] `pytest tests/test_dashboard.py` (Playwright) pasa con flujo UI completo
- [ ] Manual integration test (curl + jq) ejecuta pipeline completo y produce `data/posts.json` con N×plataformas posts
- [ ] Dashboard en `http://localhost:8000` muestra 3 columnas, sliders responden, botón "Run pipeline" ejecuta en background, log polling actualiza UI, posts aparecen con botón copiar
- [ ] Failure modes documentados funcionan: sin `GEMINI_API_KEY` → 503, sin Reddit creds → warning + continúa, doble-click run → 409, sources.json malformado → 422
- [ ] User aprueba explícitamente tras revisar Final Verification Wave

### Must Have
- Pipeline ejecutable como `BackgroundTasks` de FastAPI con estado en memoria
- Guard de concurrencia (409 si pipeline running)
- Dedup persistente con `seen_urls.json` capado
- Rate limiting Gemini con backoff + skip-and-continue
- Atomic writes en helpers de storage
- Reddit OAuth con token one-shot por run
- HN limitado a primeros 100-150 IDs
- Gemini con `response_mime_type="application/json"` en curator
- `system_instruction` en español (no en prompt repetido)
- Validación de límites de caracteres por plataforma con truncado + warning
- `User-Agent` Reddit configurable
- Frontend rehidrata estado al cargar
- Empty-result handling en cada paso (warning, no crash)
- Pre-check de `GEMINI_API_KEY` al arrancar (log últimos 4 chars)
- Logging de tokens usados por cada llamada Gemini
- Caja de "comando agéntico" visible-pero-deshabilitada con comentario `ponytail: Fase 2 only`

### Must NOT Have (Guardrails — anti scope creep)
- ❌ Newsletter / Substack / boletín (es Fase 2+)
- ❌ Guiones de vídeo / shorts / render de vídeo (Whisper, MoviePy, CapCut) — futuro
- ❌ Métricas de engagement / adaptación del agente / dashboard de uso — "en el futuro"
- ❌ Publicación automática a redes (X API, LinkedIn API) — copy-paste manual
- ❌ Scraping de X/Twitter o Meta/Threads — free tier inservible
- ❌ Chat agentic con tools dinámicos / function calling complejo — pipeline fijo
- ❌ Base de datos (SQLite, Postgres, Redis) — JSON files
- ❌ WebSockets / SSE / Celery — polling cada 2s
- ❌ Tailwind / Node / npm / TypeScript / build step — CSS y JS planos
- ❌ Autenticación / multi-usuario / login — local single-user
- ❌ Docker / Kubernetes — no necesario
- ❌ langchain, litellm, praw, loguru, pydantic-settings, fastapi-cors — no se instalan
- ❌ `pipeline/storage.py` como archivo aparte — helpers en `__init__.py`
- ❌ `tests/__init__.py` — pytest moderno no lo necesita
- ❌ Pre-commit hooks, secret scanners — `.gitignore` confianza
- ❌ Generación de imágenes / multimedia — solo texto
- ❌ Multiidioma / i18n / inglés — solo español
- ❌ Historial de runs, rotación de archivos, dashboards históricos — sobrescribir
- ❌ Tests unitarios por función — smoke end-to-end suficiente
- ❌ Modo dark/light, animaciones decorativas — CSS plano único
- ❌ Plantillas de prompts editables en UI — prompts en código
- ❌ Notificaciones por email / push — UI polling
- ❌ Hash SHA de URLs para dedup — la URL ES la key
- ❌ Locks de archivo, dos-phase commit, intent files — single-user
- ❌ Cachear Reddit token a disco — one-shot por run
- ❌ Wizard de setup CLI — README + `.env.example` basta
- ❌ Embed de `uvicorn.run()` en `app.py` — comando externo `uvicorn app:app`
- ❌ Bind a `0.0.0.0` por defecto — localhost only

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — toda verificación es agent-executable. Cero criterios tipo "el usuario revisa visualmente".

### Test Decision
- **Infrastructure exists**: NO (greenfield)
- **Set up testing**: SÍ — pytest + httpx (TestClient) + Playwright
- **Automated tests**: Smoke tests (no TDD pesado, no unitarios por función)
- **Framework**: pytest 8.x + Playwright Python
- **Coverage target**: cada endpoint público + failure modes críticos (sin Gemini key, sin Reddit creds, doble-run, sources malformado)

### QA Policy
Cada tarea de implementación MUST incluir QA scenarios agent-executable (Playwright para UI, curl/Bash para API, pytest para tests). Evidence guardado en `.sisyphus/evidence/task-{N}-{slug}.{ext}`.

- **Backend (API)**: `Bash` con `curl` + `jq` → asserts de status code + JSON fields
- **Frontend (Dashboard)**: `Playwright` (skill playwright) → navigate, fill, click, asserts DOM, screenshots
- **CLI (arranque)**: `Bash` (uvicorn en background) → asserts de logs de startup y health endpoint

### Failure Modes Obligatorios
1. Arrancar sin `GEMINI_API_KEY` → app arranca, dashboard carga, endpoints LLM devuelven 503
2. Arrancar sin Reddit creds → scraper omite Reddit, sigue con HN+RSS, response incluye warning
3. Sources.json corrupto → `/api/sources` devuelve 422 con detalle
4. Doble POST `/api/pipeline/run-all` → segundo devuelve 409
5. Run con keywords/sources que devuelven 0 artículos → 200 con `warning`, UI muestra banner amarillo

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation - parallel, sin dependencias entre ellas):
├── Task 1: Config files + sources.json defaults [quick]
├── Task 2: pipeline/__init__.py (helpers JSON atomic + globals) [quick]
├── Task 3: Static HTML skeleton (estructura 3-columnas) [visual-engineering]
├── Task 4: Static styles.css (grid + componentes) [visual-engineering]
└── Task 5: README Quickstart en español [writing]

Wave 2 (Core modules - parallel, dependen de Wave 1):
├── Task 6: pipeline/scraper.py (Reddit + HN + RSS + dedup) [unspecified-high]
├── Task 7: pipeline/curator.py (Gemini ranking + summary + JSON mode) [unspecified-high]
├── Task 8: pipeline/generator.py (Gemini posts por plataforma) [unspecified-high]
└── Task 9: app.py endpoints + BackgroundTasks plumbing [deep]

Wave 3 (Integration & frontend logic - parallel):
├── Task 10: static/app.js (sliders, polling, rehidratación, copy buttons) [visual-engineering]
├── Task 11: tests/test_api.py (smoke + failure modes) [unspecified-high]
└── Task 12: tests/test_dashboard.py (Playwright UI flow) [unspecified-high]

Wave FINAL (4 reviews paralelos, luego user okay):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA end-to-end (unspecified-high)
└── Task F4: Scope fidelity check (deep)
→ Presentar resultados → Esperar user okay explícito

Critical Path: T1+T2 → T6 → T9 → T10 → T11/T12 → F1-F4 → user okay
Parallel Speedup: ~60% vs sequential
Max Concurrent: 5 (Wave 1)
```

### Dependency Matrix

| Task | Depends on | Blocks | Wave |
|------|------------|--------|------|
| T1 (config) | - | T6, T7, T8, T9 | 1 |
| T2 (helpers) | - | T6, T7, T8, T9 | 1 |
| T3 (HTML) | - | T4, T10 | 1 |
| T4 (CSS) | T3 | T10 | 1 |
| T5 (README) | - | - | 1 |
| T6 (scraper) | T1, T2 | T9 | 2 |
| T7 (curator) | T1, T2 | T9 | 2 |
| T8 (generator) | T1, T2 | T9 | 2 |
| T9 (app.py) | T1, T2, T6, T7, T8 | T10, T11, T12 | 2 |
| T10 (app.js) | T3, T4, T9 | T12 | 3 |
| T11 (tests API) | T9 | F1-F4 | 3 |
| T12 (tests UI) | T10 | F1-F4 | 3 |
| F1-F4 | All | user okay | FINAL |

### Agent Dispatch Summary

| Wave | Tasks | Agent assignment |
|------|-------|------------------|
| 1 | T1-T5 | T1→`quick`, T2→`quick`, T3→`visual-engineering`, T4→`visual-engineering`, T5→`writing` |
| 2 | T6-T9 | T6→`unspecified-high`, T7→`unspecified-high`, T8→`unspecified-high`, T9→`deep` |
| 3 | T10-T12 | T10→`visual-engineering`, T11→`unspecified-high`, T12→`unspecified-high` |
| FINAL | F1-F4 | F1→`oracle`, F2→`unspecified-high`, F3→`unspecified-high`, F4→`deep` |

---

## TODOs

> Cada tarea = implementación + tests + QA scenarios en un solo paso. No separar.
> Toda tarea SIN QA Scenarios está INCOMPLETA.

- [x] 1. **Archivos de configuración inicial**

  **What to do**:
  - Crear `requirements.txt` con versiones pineadas: `fastapi==0.115.6`, `uvicorn[standard]==0.32.1`, `httpx==0.28.1`, `feedparser==6.0.11`, `google-generativeai==0.8.3`, `python-dotenv==1.0.1`, `pydantic==2.10.4`, `pytest==8.3.4`, `playwright==1.49.1`
  - Crear `.env.example` con: `GEMINI_API_KEY=...` (link comentario: https://aistudio.google.com/app/apikey), `REDDIT_CLIENT_ID=...`, `REDDIT_CLIENT_SECRET=...` (link: https://www.reddit.com/prefs/apps), `REDDIT_USER_AGENT=trend-pulse-bot/0.1 by /u/<TU_USUARIO>`
  - Crear `.gitignore` con: `.env`, `data/`, `__pycache__/`, `*.pyc`, `.venv/`, `.pytest_cache/`, `.playwright/`, `node_modules/` (defensivo aunque no lo usemos)
  - Crear `sources.json` con defaults: `{"subreddits": ["MachineLearning", "LocalLLaMA", "artificial", "singularity"], "rss_feeds": ["https://tldr.tech/api/rss/ai"], "hn_keywords": ["ai", "llm", "gpt", "claude", "gemini", "anthropic", "openai", "deepseek", "mistral", "agent"], "_comment": "Editar este archivo para añadir más fuentes. Schema validado por Pydantic en /api/sources."}`

  **Must NOT do**:
  - No incluir `langchain`, `praw`, `loguru`, `pydantic-settings`, `redis`, `celery`, `fastapi-cors`
  - No usar `>=` en versiones (pinear exacto)
  - No commitear `.env` real
  - No crear `data/` (lo crea la app al arrancar)

  **Recommended Agent Profile**:
  - **Category**: `quick` — archivos cortos sin lógica
  - **Skills**: `[]` — no se necesita skill especializada
  - **Skills Evaluated but Omitted**: `nodejs-best-practices` (es proyecto Python), `zod` (es Pydantic)

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (con T2, T3, T4, T5)
  - **Blocks**: T6, T7, T8, T9 (necesitan `requirements.txt` + `.env.example` para arrancar)
  - **Blocked By**: None

  **References**:
  - Draft: `.sisyphus/drafts/fase-1-motor-cableado.md` — sección "Stack backend" + "Configuración"
  - Plan: este archivo, sección "Must NOT Have" para lista completa de deps prohibidas
  - External: https://aistudio.google.com/app/apikey (Gemini), https://www.reddit.com/prefs/apps (Reddit OAuth)

  **WHY Each Reference Matters**:
  - Las versiones pineadas garantizan reproducibilidad (Metis directiva K)
  - `.env.example` con links reduce fricción de first-run (Metis concern 11)
  - `sources.json` con defaults asegura primer run funcional sin editar nada

  **Acceptance Criteria**:
  - [ ] Archivo `requirements.txt` existe con exactamente las 9 deps especificadas con `==`
  - [ ] Archivo `.env.example` existe con 4 variables + links comentados a providers
  - [ ] Archivo `.gitignore` excluye `.env` y `data/`
  - [ ] Archivo `sources.json` valida con `python -c "import json; json.load(open('sources.json'))"` exit 0
  - [ ] `grep -E 'langchain|praw|loguru|pydantic-settings' requirements.txt` exit 1 (no match)

  **QA Scenarios**:
  ```
  Scenario: Configuración mínima válida
    Tool: Bash
    Preconditions: Repo limpio sin estos archivos
    Steps:
      1. Verificar `cat requirements.txt | wc -l` → ≥9 líneas
      2. Verificar `python -c "import json; print(json.load(open('sources.json'))['hn_keywords'])"` → lista con "ai"
      3. Verificar `cat .gitignore | grep -c '^\.env$'` → 1
      4. Verificar `cat .env.example | grep -c '^GEMINI_API_KEY='` → 1
    Expected Result: Todos los exit codes = 0, conteos correctos
    Evidence: .sisyphus/evidence/task-1-config-validation.txt

  Scenario: Bloqueo de dependencias prohibidas
    Tool: Bash
    Steps:
      1. `grep -E 'langchain|praw|loguru|pydantic-settings|fastapi-cors|litellm' requirements.txt`
    Expected Result: exit 1 (no matches) — si encuentra alguna, FAIL
    Evidence: .sisyphus/evidence/task-1-deps-veto.txt
  ```

  **Evidence to Capture**:
  - [ ] `.sisyphus/evidence/task-1-config-validation.txt` (output de los grep + json validation)
  - [ ] `.sisyphus/evidence/task-1-deps-veto.txt` (output de grep vetos)

  **Commit**: YES (groups solo)
  - Message: `chore: initial config, env example, sources defaults`
  - Files: `.gitignore`, `.env.example`, `sources.json`, `requirements.txt`
  - Pre-commit: `python -c "import json; json.load(open('sources.json'))"`

- [x] 2. **Helpers de storage + estado compartido (`pipeline/__init__.py`)**

  **What to do**:
  - Crear carpeta `pipeline/` con `__init__.py`
  - Implementar `read_json(path: Path) -> Any` — devuelve `{}` o `[]` (según default arg) si no existe, sino `json.load`
  - Implementar `write_json(path: Path, data: Any) -> None` — atomic: escribe a `path.with_suffix(path.suffix + ".tmp")`, luego `os.replace(tmp, path)`. Crea directorio padre con `mkdir(parents=True, exist_ok=True)` si no existe
  - Implementar `pipeline_state: dict` global: `{"running": False, "step": None, "progress": None, "started_at": None, "finished_at": None, "error": None, "warning": None}`
  - Implementar `logs: deque` global con `maxlen=200`
  - Implementar `log(level: str, msg: str)` helper que appendea a `logs` un dict `{"ts": datetime.now(timezone.utc).isoformat(), "level": level, "msg": msg}` y también imprime a stdout
  - Constantes: `DATA_DIR = Path("./data")`, `SEEN_URLS_PATH = DATA_DIR / "seen_urls.json"`, `NEWS_RAW_PATH`, `NEWS_CURATED_PATH`, `POSTS_PATH`, `LLM_LOG_PATH = DATA_DIR / "llm_calls.jsonl"`
  - Implementar `add_seen_url(url: str)` y `is_seen(url: str) -> bool` que persisten en `seen_urls.json` capado a 1000 (slice `[-1000:]` al guardar)
  - Implementar `log_llm_call(step: str, tokens_in: int, tokens_out: int, latency_s: float)` — appendea a deque + opcional append a `llm_calls.jsonl`

  **Must NOT do**:
  - NO crear `pipeline/storage.py` (Metis directiva — helpers van AQUÍ en `__init__.py`)
  - NO usar `pickle` para storage (JSON solo)
  - NO usar locks de archivo (single-user)
  - NO usar `logging` library (deque + print basta)
  - NO hash SHA de URLs para dedup (la URL es la key)
  - NO cargar `seen_urls.json` en memoria globalmente — leer del disco en `is_seen` (es un archivo pequeño)

  **Recommended Agent Profile**:
  - **Category**: `quick` — módulo de ~80 LOC sin lógica compleja
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**: `vitest` (es Python no JS), `typescript-advanced-types` (Python sin tipos avanzados)

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (con T1, T3, T4, T5)
  - **Blocks**: T6, T7, T8, T9
  - **Blocked By**: None

  **References**:
  - Plan: este archivo, sección "Metis Review" subsección "Concerns resueltos" — directivas sobre atomic writes, dedup capado, deque maxlen 200
  - Plan: sección "Must NOT Have" — `storage.py` prohibido
  - External: Python `pathlib`, `collections.deque`, `os.replace` semantics

  **WHY Each Reference Matters**:
  - Atomic write previene archivos corruptos si proceso muere mid-write (Metis concern 7)
  - Deque `maxlen=200` evita crecimiento ilimitado sin código extra (Metis concern 6)
  - `is_seen` lee del disco cada vez para que ediciones manuales del JSON sean efectivas inmediatamente

  **Acceptance Criteria**:
  - [ ] `python -c "from pipeline import read_json, write_json, log, pipeline_state, logs"` exit 0
  - [ ] `python -c "from pipeline import read_json; print(read_json('does_not_exist.json', default={}))"` → `{}`
  - [ ] Test: `write_json('/tmp/test.json', {'a': 1})` produce archivo, y `read_json('/tmp/test.json')` devuelve `{'a': 1}`
  - [ ] Test: durante `write_json`, NO debe existir el archivo final hasta el `os.replace` (atomic)
  - [ ] Test: `is_seen("https://a")` False inicial, `add_seen_url("https://a")`, luego `is_seen("https://a")` True
  - [ ] Test: añadir 1100 URLs, `len(read_json(SEEN_URLS_PATH))` ≤ 1000

  **QA Scenarios**:
  ```
  Scenario: Atomic write no deja basura si falla
    Tool: Bash
    Preconditions: `/tmp/test.json` no existe
    Steps:
      1. python -c "from pipeline import write_json; write_json('/tmp/test.json', {'k':1})"
      2. ls /tmp/test.json.tmp  → exit 1 (no debe quedar)
      3. cat /tmp/test.json  → '{"k": 1}'
    Expected Result: archivo final existe sin .tmp residual
    Evidence: .sisyphus/evidence/task-2-atomic-write.txt

  Scenario: Cap de seen_urls a 1000
    Tool: Bash
    Steps:
      1. python -c "from pipeline import add_seen_url, SEEN_URLS_PATH, read_json; [add_seen_url(f'https://x/{i}') for i in range(1100)]; print(len(read_json(SEEN_URLS_PATH, default=[])))"
    Expected Result: output exactamente 1000
    Evidence: .sisyphus/evidence/task-2-seen-cap.txt

  Scenario: NO existe pipeline/storage.py
    Tool: Bash
    Steps:
      1. test ! -f pipeline/storage.py
    Expected Result: exit 0 (archivo NO existe — anti-slop check)
    Evidence: .sisyphus/evidence/task-2-no-storage-py.txt
  ```

  **Evidence to Capture**:
  - [ ] `.sisyphus/evidence/task-2-atomic-write.txt`
  - [ ] `.sisyphus/evidence/task-2-seen-cap.txt`
  - [ ] `.sisyphus/evidence/task-2-no-storage-py.txt`

  **Commit**: YES (groups solo)
  - Message: `feat(pipeline): storage helpers and shared state`
  - Files: `pipeline/__init__.py`
  - Pre-commit: `python -m py_compile pipeline/__init__.py`

- [x] 3. **Frontend HTML skeleton (`static/index.html`)**

  **What to do**:
  - Crear `static/index.html` con estructura semántica:
    - `<title>TrendPulse — Pipeline Agentic IA</title>`
    - Layout principal: `<div id="dashboard">` con tres columnas: `<aside id="col-left">`, `<main id="col-center">`, `<aside id="col-right">`
    - **Col-left (25%)**: título "Control", sección "Configuración" con `<input type="range" id="slider-top-n" min="3" max="20" value="5">` + label dinámico, checkboxes para plataformas (`x`, `linkedin`, `threads`) todos checked por default, sección "Pipeline" con botones `#btn-scrape`, `#btn-curate`, `#btn-generate`, `#btn-run-all`, sección "Estado" con `<div id="pipeline-status">`
    - **Col-center (50%)**: caja agéntica DESHABILITADA: `<input id="nl-input" type="text" disabled placeholder="Disponible en Fase 2 (requiere agente con tools)"> <!-- ponytail: Fase 2 only - DO NOT WIRE UP -->`, debajo: `<section id="news-section">` para noticias curadas, `<section id="log-section">` con `<pre id="log-stream">` para logs
    - **Col-right (25%)**: `<section id="posts-section">` para posts generados con botón copiar por cada uno
  - Incluir `<link rel="stylesheet" href="/static/styles.css">` y `<script src="/static/app.js" defer></script>`
  - `<meta charset="utf-8">` + `<meta name="viewport" content="width=device-width,initial-scale=1">`
  - Banner de warnings: `<div id="warning-banner" hidden></div>` (mostrado por JS cuando hay warning)

  **Must NOT do**:
  - NO inline CSS (todo en `styles.css`)
  - NO inline JS (todo en `app.js`)
  - NO `<script src="https://...">` externo (sin CDN, sin Tailwind, sin Alpine, sin nada)
  - NO `data-*` attributes para business logic que requieran framework (todo via IDs únicos)
  - NO charset distinto a utf-8
  - NO acoplar texto en HTML — todos los strings visibles en español

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering` — HTML semántico + estructura UI
  - **Skills**: [`accessibility`, `seo`]
    - `accessibility`: para labels correctos en sliders/checkboxes, ARIA donde aplique
    - `seo`: `<title>` y meta description aunque sea local
  - **Skills Evaluated but Omitted**:
    - `tailwind-css-patterns`: NO usamos Tailwind
    - `vercel-react-best-practices`: NO usamos React

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (con T1, T2, T4, T5)
  - **Blocks**: T4 (CSS depende de IDs/clases del HTML), T10 (JS depende del DOM)
  - **Blocked By**: None

  **References**:
  - Plan: sección "Concrete Deliverables" — descripción del layout 3-columnas
  - Plan: sección "Must NOT Have" — sin Tailwind, sin CDN, sin frameworks JS
  - README.md original (líneas 99-110): especificación de paneles (Layout Grid 25/50/25)

  **WHY Each Reference Matters**:
  - Layout 25/50/25 viene del README original — respetar la visión del usuario
  - Caja agéntica visible-deshabilitada con comentario `ponytail:` previene wireado accidental (Metis recomendación específica)

  **Acceptance Criteria**:
  - [ ] `curl -sf http://localhost:8000/ | grep -c 'col-left\|col-center\|col-right'` → 3 (los tres IDs presentes)
  - [ ] `curl -sf http://localhost:8000/ | grep 'ponytail: Fase 2 only'` exit 0
  - [ ] `curl -sf http://localhost:8000/ | grep 'id="nl-input"' | grep -c 'disabled'` → 1
  - [ ] `curl -sf http://localhost:8000/ | grep -c 'id="slider-top-n"'` → 1
  - [ ] `curl -sf http://localhost:8000/ | grep -c 'value="x"\|value="linkedin"\|value="threads"'` → 3
  - [ ] HTML validate: no errors fatales (puede usar `html5validator` si está disponible, sino skip)

  **QA Scenarios**:
  ```
  Scenario: Estructura básica correcta
    Tool: Playwright (skill: playwright)
    Preconditions: `uvicorn app:app` corriendo en background
    Steps:
      1. browser_navigate("http://localhost:8000/")
      2. browser_snapshot()
      3. Assert: tres elementos visibles con IDs col-left, col-center, col-right
      4. Assert: `#nl-input` tiene atributo `disabled` = true
      5. Assert: `#nl-input` placeholder contiene "Fase 2"
      6. Assert: tres checkboxes con values x, linkedin, threads existen y checked=true por default
      7. Assert: slider top-n existe con min=3 max=20 value=5
    Expected Result: todas las asserts pasan
    Evidence: .sisyphus/evidence/task-3-html-structure.png (screenshot)

  Scenario: NO hay referencias externas (CDN, frameworks)
    Tool: Bash
    Steps:
      1. grep -E 'cdn\.|googleapis|jsdelivr|unpkg|tailwind' static/index.html
    Expected Result: exit 1 (no matches)
    Evidence: .sisyphus/evidence/task-3-no-cdn.txt
  ```

  **Evidence to Capture**:
  - [ ] `.sisyphus/evidence/task-3-html-structure.png` (Playwright screenshot)
  - [ ] `.sisyphus/evidence/task-3-no-cdn.txt`

  **Commit**: YES (groups con T4)
  - Message: `feat(ui): dashboard skeleton with 3-column layout`
  - Files: `static/index.html` (+ `static/styles.css` del T4)
  - Pre-commit: `grep 'ponytail: Fase 2 only' static/index.html`

- [x] 4. **Frontend CSS (`static/styles.css`)**

  **What to do**:
  - Reset minimal: `* { box-sizing: border-box; margin: 0; padding: 0; }`, `body { font-family: system-ui, -apple-system, sans-serif; line-height: 1.5; background: #0f172a; color: #e2e8f0; }`
  - Layout: `#dashboard { display: grid; grid-template-columns: 25% 50% 25%; height: 100vh; gap: 1rem; padding: 1rem; }`
  - Cada columna `aside, main { background: #1e293b; border-radius: 8px; padding: 1rem; overflow-y: auto; }`
  - Botones: estilo consistente, hover state, disabled state visible
  - Slider y checkboxes: estilo legible sobre fondo oscuro
  - `#log-stream`: `font-family: 'SF Mono', Consolas, monospace; font-size: 0.85rem; background: #0a0f1a; padding: 0.5rem; max-height: 40vh; overflow-y: auto;`
  - Card style para items de news y posts: borde sutil, padding, espaciado entre
  - `#warning-banner`: amarillo/naranja con texto contrastante, padding, margen visible
  - `#nl-input`: estilo "deshabilitado" claro (opacity reducido, cursor not-allowed)
  - Estado "running" del pipeline: indicador visual (puede ser texto + emoji/spinner CSS)
  - Botón "copiar": pequeño, junto a cada post, con feedback al hacer click (cambia texto a "Copiado!")
  - Media queries: en pantallas <900px, columnas se apilan (stack vertical)

  **Must NOT do**:
  - NO usar Tailwind ni clases utility frameworks
  - NO usar `@import` de Google Fonts (offline-first)
  - NO animaciones decorativas (transiciones simples sí, animaciones complejas no)
  - NO modo dark/light toggle (un solo tema oscuro)
  - NO usar `!important` salvo casos justificados

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering` — CSS plano con diseño claro
  - **Skills**: [`accessibility`]
    - `accessibility`: contraste de colores legible, focus states visibles
  - **Skills Evaluated but Omitted**:
    - `tailwind-css-patterns`: explícitamente NO usamos Tailwind
    - `frontend-design`: pertinente pero el scope es "funcional y legible", no "distintivo"

  **Parallelization**:
  - **Can Run In Parallel**: NO (depende de IDs/clases del HTML)
  - **Parallel Group**: Wave 1 (con T1, T2, T5, después de T3)
  - **Blocks**: T10 (JS no depende del CSS directamente pero la UI integral sí)
  - **Blocked By**: T3 (necesita IDs del HTML)

  **References**:
  - T3 `static/index.html` — IDs y estructura DOM a estilizar
  - Plan sección "Must NOT Have" — sin Tailwind, sin frameworks
  - WCAG 2.2 contrast ratios (AA mínimo 4.5:1)

  **WHY Each Reference Matters**:
  - HTML define la estructura; CSS solo decora
  - Contraste accesible asegura usabilidad básica
  - Sin Tailwind = sin build step, alineado con ponytail

  **Acceptance Criteria**:
  - [ ] `static/styles.css` existe y se sirve en `/static/styles.css` con status 200
  - [ ] `grep -E '@import.*googleapis|tailwind' static/styles.css` exit 1
  - [ ] Layout 3-columnas visible en Playwright snapshot (cada columna ocupa su % asignado)
  - [ ] Estado disabled del `#nl-input` se ve visualmente diferente (opacity)
  - [ ] `#warning-banner` cuando se muestra es visible (no display:none por error)

  **QA Scenarios**:
  ```
  Scenario: Layout 3-columnas renderiza correctamente
    Tool: Playwright (skill: playwright)
    Preconditions: server corriendo
    Steps:
      1. browser_navigate("http://localhost:8000/")
      2. browser_evaluate("window.getComputedStyle(document.getElementById('dashboard')).gridTemplateColumns")
      3. Assert: result contiene tres valores (25/50/25 o equivalente en px)
      4. browser_screenshot() → guardar
    Expected Result: tres columnas visibles, no apiladas en desktop (>900px)
    Evidence: .sisyphus/evidence/task-4-layout-desktop.png

  Scenario: Sin dependencias externas en CSS
    Tool: Bash
    Steps:
      1. grep -cE '@import.*http|googleapis|tailwind|cdn\.' static/styles.css
    Expected Result: 0 matches
    Evidence: .sisyphus/evidence/task-4-no-external-css.txt
  ```

  **Evidence to Capture**:
  - [ ] `.sisyphus/evidence/task-4-layout-desktop.png`
  - [ ] `.sisyphus/evidence/task-4-no-external-css.txt`

  **Commit**: YES (groups con T3)
  - Message: `feat(ui): dashboard skeleton with 3-column layout` (commit conjunto)
  - Files: `static/styles.css`
  - Pre-commit: `grep -cE '@import.*http' static/styles.css` debe ser 0

- [x] 5. **README Quickstart en español**

  **What to do**:
  - Añadir al `README.md` existente (NO sobrescribir, solo apendear) una nueva sección al final:
    ```markdown
    ---

    ## Quickstart (Fase 1)

    > Pipeline agentic de contenido corto: scrapea noticias IA → curan con Gemini → genera posts cortos en español para X / LinkedIn / Threads.

    ### Requisitos
    - Python 3.11 o superior
    - Cuenta gratuita en Google AI Studio (Gemini): https://aistudio.google.com/app/apikey
    - Cuenta Reddit + app registrada como "script": https://www.reddit.com/prefs/apps

    ### Instalación
    \`\`\`bash
    git clone <repo>
    cd trend-pulse
    python -m venv .venv
    source .venv/bin/activate  # Windows: .venv\Scripts\activate
    pip install -r requirements.txt
    cp .env.example .env
    # Editar .env con las 3 keys (links en el archivo)
    \`\`\`

    ### Ejecución
    \`\`\`bash
    uvicorn app:app
    # Abrir http://localhost:8000
    \`\`\`

    ### Uso
    1. Configura cuántas noticias quieres procesar (slider) y qué plataformas (checkboxes)
    2. Pulsa "Ejecutar pipeline completo" (o cada paso por separado)
    3. Espera a que termine (~1-2 minutos según volumen)
    4. Copia los posts generados desde la columna derecha

    ### Fuentes incluidas por defecto
    - Reddit: r/MachineLearning, r/LocalLLaMA, r/artificial, r/singularity
    - Hacker News: top stories filtradas por keywords IA
    - RSS: TLDR AI

    Edita `sources.json` para añadir más subreddits, feeds RSS o keywords.

    ### Troubleshooting
    - **"Falta GEMINI_API_KEY"**: edita `.env` con tu key de Google AI Studio
    - **"Reddit auth failed"**: verifica que `REDDIT_USER_AGENT` incluye tu username real (`/u/tu_usuario`)
    - **"Quota diaria agotada"**: Gemini free tier permite ~1500 calls/día, vuelve mañana
    - **Página no carga estilos**: abre `http://localhost:8000`, NO el archivo HTML directo

    ### Qué NO hace Fase 1
    - No publica automáticamente a redes (copy-paste manual)
    - No genera imágenes ni vídeo
    - No envía newsletter
    - No mide métricas de engagement
    - No usa X/Twitter ni Meta/Threads como fuentes (free tier no útil)

    Estas funcionalidades llegan en fases posteriores.
    ```

  **Must NOT do**:
  - NO reemplazar contenido existente del README
  - NO incluir capturas de pantalla (innecesario para Fase 1)
  - NO documentar arquitectura interna detallada (eso está en el README original)
  - NO usar `npm`, `yarn`, `bun` ni nada de Node
  - NO sugerir Docker

  **Recommended Agent Profile**:
  - **Category**: `writing` — documentación de usuario
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**: documentación técnica avanzada no aplica

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (independiente)
  - **Blocks**: None (es documentación)
  - **Blocked By**: None

  **References**:
  - `README.md` existente (líneas 1-149) — respetar contenido previo
  - `.env.example` del T1 — los links a providers deben coincidir
  - Plan sección "Must NOT Have" — comunicar correctamente qué NO hace Fase 1

  **WHY Each Reference Matters**:
  - First-run UX es crítico (Metis concern 11) — Quickstart debe llevar a "posts en pantalla" en ≤5 minutos
  - Comunicar EXCLUSIONS evita expectativas erradas

  **Acceptance Criteria**:
  - [ ] `README.md` contiene sección `## Quickstart (Fase 1)` (grep)
  - [ ] Contenido original (líneas 1-149) intacto (`head -149 README.md` igual que antes)
  - [ ] Sección incluye comandos `pip install`, `cp .env.example .env`, `uvicorn app:app`
  - [ ] Sección lista las 3 fuentes (Reddit, HN, RSS) explícitamente
  - [ ] Sección lista al menos 4 cosas que NO hace Fase 1

  **QA Scenarios**:
  ```
  Scenario: README actualizado sin perder contenido original
    Tool: Bash
    Preconditions: README.md original tiene 149 líneas
    Steps:
      1. wc -l README.md  → debe ser >149
      2. head -149 README.md > /tmp/original.md
      3. git show HEAD:README.md > /tmp/before.md  (si está en git)
      4. diff /tmp/original.md /tmp/before.md  → exit 0 (sin diferencias)
      5. grep -q "## Quickstart (Fase 1)" README.md
      6. grep -q "uvicorn app:app" README.md
      7. grep -q "GEMINI_API_KEY" README.md
    Expected Result: original preservado + sección nueva añadida con comandos clave
    Evidence: .sisyphus/evidence/task-5-readme-diff.txt

  Scenario: Sin referencias a Node/Docker en Quickstart
    Tool: Bash
    Steps:
      1. sed -n '/## Quickstart/,$p' README.md | grep -iE 'npm|yarn|bun|docker|node_modules'
    Expected Result: exit 1 (no matches)
    Evidence: .sisyphus/evidence/task-5-no-node-docker.txt
  ```

  **Evidence to Capture**:
  - [ ] `.sisyphus/evidence/task-5-readme-diff.txt`
  - [ ] `.sisyphus/evidence/task-5-no-node-docker.txt`

  **Commit**: YES (solo)
  - Message: `docs: quickstart in spanish`
  - Files: `README.md`
  - Pre-commit: `grep -q "## Quickstart (Fase 1)" README.md`

- [x] 6. **Pipeline scraper (`pipeline/scraper.py`)**

  **What to do**:
  - Implementar `async def scrape_all(sources: dict) -> list[dict]` que orquesta los tres scrapers en paralelo (asyncio.gather) y devuelve una lista deduplicada de noticias
  - Implementar `async def scrape_reddit(client: httpx.AsyncClient, subreddits: list[str]) -> list[dict]`:
    - Obtener token OAuth one-shot via POST a `https://www.reddit.com/api/v1/access_token` con Basic Auth (client_id:secret) + `grant_type=client_credentials`
    - Para cada subreddit, GET a `https://oauth.reddit.com/r/{sub}/hot.json?limit=25` con `Authorization: Bearer <token>` y header `User-Agent` desde env `REDDIT_USER_AGENT`
    - Mapear cada post a `{"source": "reddit", "subreddit": sub, "title": post["title"], "url": post["url"], "score": post["score"], "created_utc": post["created_utc"]}`
    - Si `REDDIT_CLIENT_ID` o `REDDIT_CLIENT_SECRET` faltan: log warning, return `[]` (no crash)
  - Implementar `async def scrape_hn(client: httpx.AsyncClient, keywords: list[str], max_ids: int = 120) -> list[dict]`:
    - GET a `https://hacker-news.firebaseio.com/v0/topstories.json` → tomar primeros `max_ids`
    - Para cada ID en paralelo (asyncio.gather con semáforo de 20): GET `/v0/item/{id}.json`
    - Filtrar por `any(kw.lower() in item["title"].lower() for kw in keywords)` y `item["type"] == "story"`
    - Mapear a `{"source": "hn", "title": item["title"], "url": item.get("url") or f"https://news.ycombinator.com/item?id={id}", "score": item["score"], "created_utc": item["time"]}`
  - Implementar `def scrape_rss(feed_urls: list[str]) -> list[dict]` (sync con feedparser):
    - Para cada feed: `feedparser.parse(url)`, para cada entry: `{"source": "rss", "feed": url, "title": entry.title, "url": entry.link, "score": 0, "created_utc": <parse entry.published_parsed o now()>}`
    - Manejar `published_parsed = None` con fallback a `datetime.now(timezone.utc).timestamp()`
  - Dedup: filtrar por `not is_seen(url)`, también dedup intra-batch por set de URLs
  - Tras devolver la lista, llamar `add_seen_url(url)` para cada URL devuelta
  - Logging: `log("info", "Scraping reddit/{sub}: N items")` por subreddit, `log("warning", "Reddit creds missing, skipping")` si aplica

  **Must NOT do**:
  - NO usar `praw` (cliente Reddit oficial Python) — usar httpx directo
  - NO usar `requests` (sync) — todo async excepto feedparser (no tiene async)
  - NO cachear el token Reddit a disco
  - NO hash SHA de URLs para dedup
  - NO traer los 500 IDs completos de HN (capar a 120)
  - NO usar regex con `\b` word boundaries en HN filter
  - NO bloquear si una fuente falla — log + continuar

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — lógica de scraping con async + manejo de errores
  - **Skills**: [`nodejs-backend-patterns`]
    - `nodejs-backend-patterns`: aunque es Python, los patterns de retry/error handling aplican conceptualmente
  - **Skills Evaluated but Omitted**:
    - `nodejs-best-practices`: aplica menos directamente a Python async

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (con T7, T8)
  - **Blocks**: T9 (app.py importa el scraper)
  - **Blocked By**: T1 (config), T2 (helpers)

  **References**:
  - Plan sección "Metis Review" — A (concurrencia), F (User-Agent), G (HN throughput limit)
  - Plan sección "Must NOT Have" — sin praw, sin requests
  - External: Reddit API docs (https://www.reddit.com/dev/api/oauth), HN API Firebase docs
  - T2 helpers: `is_seen`, `add_seen_url`, `log`

  **WHY Each Reference Matters**:
  - HN devuelve 500 IDs por default; capar a 120 da 5x menos requests sin perder valor (Metis G)
  - Reddit User-Agent estricto: User-Agent genérico → ban (Metis F)
  - One-shot token: pipeline run dura <2min, expiración 1h irrelevante

  **Acceptance Criteria**:
  - [ ] `python -c "from pipeline.scraper import scrape_all, scrape_reddit, scrape_hn, scrape_rss"` exit 0
  - [ ] `scrape_all` con sources vacíos devuelve `[]` sin crash
  - [ ] `scrape_all` con keywords HN bien definidos y RSS válido devuelve >0 items en run con red
  - [ ] Sin `REDDIT_CLIENT_ID` en env: scraper Reddit devuelve `[]` con warning loggeado
  - [ ] Re-run inmediato: 100% de URLs filtradas como seen (segundo run devuelve 0 o muy pocos nuevos)
  - [ ] `seen_urls.json` tras el run tiene URLs nuevas registradas

  **QA Scenarios**:
  ```
  Scenario: Scraper Reddit funciona con creds reales
    Tool: Bash
    Preconditions: .env tiene REDDIT_CLIENT_ID, REDDIT_CLIENT_SECRET, REDDIT_USER_AGENT válidos
    Steps:
      1. python -c "
         import asyncio, os, httpx
         from pipeline.scraper import scrape_reddit
         from dotenv import load_dotenv; load_dotenv()
         async def main():
             async with httpx.AsyncClient() as c:
                 r = await scrape_reddit(c, ['MachineLearning'])
                 print(len(r), r[0]['source'] if r else 'empty')
         asyncio.run(main())
         "
    Expected Result: imprime un número >0 + "reddit", sin excepciones
    Evidence: .sisyphus/evidence/task-6-reddit-real.txt

  Scenario: Scraper degrada elegante sin creds
    Tool: Bash
    Preconditions: REDDIT_CLIENT_ID vacío o ausente
    Steps:
      1. REDDIT_CLIENT_ID="" python -c "
         import asyncio, httpx
         from pipeline.scraper import scrape_reddit
         async def main():
             async with httpx.AsyncClient() as c:
                 r = await scrape_reddit(c, ['MachineLearning'])
                 print('items:', len(r))
         asyncio.run(main())
         "
    Expected Result: imprime "items: 0" sin crash
    Evidence: .sisyphus/evidence/task-6-reddit-no-creds.txt

  Scenario: HN keyword filter es substring case-insensitive
    Tool: Bash
    Steps:
      1. python -c "
         from pipeline.scraper import scrape_hn
         # Mock test con titles in-memory si es posible, o test unitario directo del filter
         "
      2. Alternativamente: test con HN real, asegurar que items con 'AI' o 'AIops' aparecen
    Expected Result: ambos casos matchean si keyword es 'ai'
    Evidence: .sisyphus/evidence/task-6-hn-filter.txt

  Scenario: Dedup persistente impide duplicados entre runs
    Tool: Bash
    Steps:
      1. Run 1: ejecutar scrape_all, contar items
      2. Run 2 inmediato: ejecutar scrape_all, contar items
      3. items_run2 << items_run1 (idealmente 0, máximo few por sources actualizadas)
    Expected Result: run 2 devuelve menos items
    Evidence: .sisyphus/evidence/task-6-dedup.txt
  ```

  **Evidence to Capture**:
  - [ ] `.sisyphus/evidence/task-6-reddit-real.txt` (o nota explicando por qué no se pudo con creds)
  - [ ] `.sisyphus/evidence/task-6-reddit-no-creds.txt`
  - [ ] `.sisyphus/evidence/task-6-hn-filter.txt`
  - [ ] `.sisyphus/evidence/task-6-dedup.txt`

  **Commit**: YES (solo)
  - Message: `feat(pipeline): scraper for reddit, hn, rss with dedup`
  - Files: `pipeline/scraper.py`
  - Pre-commit: `python -m py_compile pipeline/scraper.py`

- [x] 7. **Pipeline curator (`pipeline/curator.py`)**

  **What to do**:
  - Implementar `async def curate(items: list[dict], top_n: int) -> tuple[list[dict], str | None]` que devuelve `(curated, warning)`
  - Si `items` vacío: return `([], "Sin noticias para curar")`
  - Configurar Gemini: `model = genai.GenerativeModel(model_name="gemini-2.0-flash", system_instruction="Eres un editor experto en noticias de inteligencia artificial. Tu trabajo es rankear las noticias por relevancia (impacto técnico, novedad, audiencia profesional), y resumir cada una en 2-3 frases en español neutro.", generation_config={"response_mime_type": "application/json", "temperature": 0.4})`
  - Construir prompt con la lista de titles (limitar input: `title` only o `title + 200 chars snippet`)
  - Pedir output JSON: `[{"index": int, "score": int (0-100), "summary": "string en español"}, ...]`
  - Llamar `model.generate_content_async(prompt)`
  - Rate limit: ANTES de cada call hacer `await asyncio.sleep(4.1)` (margen sobre 15 RPM)
  - Backoff exponencial en error 429: retry 3 veces con sleeps 1s, 2s, 4s. Si falla los 3 → log warning y devolver lista parcial (lo que tenga score)
  - Parse JSON: try `json.loads(response.text)`, si falla strip backticks y reintentar; si aún falla → log warning + skip
  - Ordenar por `score` desc, tomar top_n
  - Mergear summary y score al item original: `{...item, "score": s, "summary": sm}`
  - Llamar `log_llm_call("curate", tokens_in, tokens_out, latency_s)` con datos de `response.usage_metadata`
  - Si no hay `GEMINI_API_KEY` en env: raise específico → caller (app.py) traduce a HTTP 503

  **Must NOT do**:
  - NO usar langchain ni litellm
  - NO usar function calling / tools de Gemini
  - NO chain-of-thought elaborado en el prompt
  - NO few-shot con muchos ejemplos (Gemini Flash es bastante bueno con instrucciones directas)
  - NO incluir contenido completo de los artículos en el prompt (solo title + snippet corto)
  - NO abortar todo el pipeline si una llamada falla — skip-and-continue
  - NO cachear API key en variable global del módulo (leer de env cada call)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — integración LLM con prompt engineering y error handling
  - **Skills**: [`zod`]
    - `zod`: aunque es Python (Pydantic), los patterns de schema validation aplican conceptualmente al parsing del JSON de Gemini
  - **Skills Evaluated but Omitted**:
    - `vercel-react-best-practices`: no aplica
    - `tailwind-css-patterns`: no aplica

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (con T6, T8)
  - **Blocks**: T9 (app.py importa curator)
  - **Blocked By**: T1, T2

  **References**:
  - Plan sección "Metis Review": rate limit (item 2), prompts Gemini (item 5), JSON malformado (D), empty results (C), límites caracteres
  - External: https://ai.google.dev/api/python/google/generativeai/GenerativeModel
  - External: `response_mime_type="application/json"` con schema validation
  - T2 helpers: `log`, `log_llm_call`

  **WHY Each Reference Matters**:
  - `system_instruction` ahorra tokens repetidos vs prompt repetido (Metis 5)
  - `response_mime_type` JSON evita parsing frágil (Metis 5)
  - 4.1s sleep entre calls = 14.6 RPM, debajo del límite 15
  - Skip-and-continue evita aborts catastróficos por un item malo

  **Acceptance Criteria**:
  - [ ] `from pipeline.curator import curate` exit 0
  - [ ] `curate([], 5)` devuelve `([], "Sin noticias para curar")` sin llamar a Gemini
  - [ ] `curate(items, 5)` con `GEMINI_API_KEY` válido y 10 items: devuelve max 5 items con campos `score` y `summary`
  - [ ] Resumen en español verificable (ej: `"el modelo"`, `"la inteligencia"` en al menos 3/5 items)
  - [ ] Sin `GEMINI_API_KEY`: raise ConfigError o similar (NO crash silencioso)
  - [ ] Log llm_call ejecutado (deque de logs contiene entrada con `step=curate`)

  **QA Scenarios**:
  ```
  Scenario: Curator con datos reales
    Tool: Bash
    Preconditions: GEMINI_API_KEY válido en .env
    Steps:
      1. python -c "
         import asyncio
         from dotenv import load_dotenv; load_dotenv()
         from pipeline.curator import curate
         items = [
           {'title': 'OpenAI releases GPT-5', 'url': 'https://example.com/1', 'source': 'hn'},
           {'title': 'Anthropic Claude 4 announced', 'url': 'https://example.com/2', 'source': 'hn'},
           {'title': 'Random gardening tips', 'url': 'https://example.com/3', 'source': 'rss'},
         ]
         curated, warning = asyncio.run(curate(items, 2))
         print('items:', len(curated))
         print('first:', curated[0] if curated else None)
         "
    Expected Result: 2 items con score y summary en español; el item de jardinería tiene score bajo o no aparece
    Evidence: .sisyphus/evidence/task-7-curate-real.txt

  Scenario: Curator falla elegante sin API key
    Tool: Bash
    Steps:
      1. GEMINI_API_KEY="" python -c "
         import asyncio
         from pipeline.curator import curate
         try:
             asyncio.run(curate([{'title': 'x', 'url': 'y', 'source': 'z'}], 1))
             print('NO_RAISE')
         except Exception as e:
             print('RAISED:', type(e).__name__)
         "
    Expected Result: imprime "RAISED: <ExceptionType>" — NO debe imprimir NO_RAISE
    Evidence: .sisyphus/evidence/task-7-no-key.txt

  Scenario: Empty input no llama a Gemini
    Tool: Bash
    Steps:
      1. python -c "
         import asyncio
         from pipeline.curator import curate
         r, w = asyncio.run(curate([], 5))
         print('items:', len(r), 'warning:', w)
         "
    Expected Result: items: 0, warning: 'Sin noticias para curar'
    Evidence: .sisyphus/evidence/task-7-empty.txt
  ```

  **Evidence to Capture**:
  - [ ] `.sisyphus/evidence/task-7-curate-real.txt`
  - [ ] `.sisyphus/evidence/task-7-no-key.txt`
  - [ ] `.sisyphus/evidence/task-7-empty.txt`

  **Commit**: YES (solo)
  - Message: `feat(pipeline): curator with gemini json mode`
  - Files: `pipeline/curator.py`
  - Pre-commit: `python -m py_compile pipeline/curator.py`

- [x] 8. **Pipeline generator (`pipeline/generator.py`)**

  **What to do**:
  - Implementar `async def generate_posts(curated: list[dict], platforms: list[str]) -> tuple[list[dict], str | None]` que devuelve `(posts, warning)`
  - Si `curated` vacío o `platforms` vacío: return `([], "Sin noticias curadas o plataformas para generar")`
  - Constantes: `LIMITS = {"x": 280, "linkedin": 3000, "threads": 500}`
  - Configurar Gemini: `model = genai.GenerativeModel("gemini-2.0-flash", system_instruction="Eres un editor de redes sociales experto. Generas posts cortos en español, claros y enganchadores, sin hashtags inventados, sin emojis excesivos, sin inventar datos. Adaptas el tono a la plataforma.", generation_config={"temperature": 0.7})`
  - Para cada `(item, platform)`:
    - Construir prompt: `f"Genera un post para {platform} (máx {LIMITS[platform]} caracteres) sobre esta noticia. Mantén el tono profesional pero accesible. Incluye 1 emoji solo si aporta. No uses hashtags inventados (puedes usar 1-2 hashtags reales del tema). Título: {item['title']}\nResumen: {item['summary']}\nURL: {item['url']}\n\nDevuelve SOLO el texto del post, sin explicaciones."`
    - Rate limit: `await asyncio.sleep(4.1)` antes de cada call
    - Backoff exponencial en 429: 1s/2s/4s, 3 retries
    - Parse `response.text` (texto plano, no JSON aquí)
    - Strip whitespace y backticks decorativos del output
    - Validar longitud: si `len(text) > LIMITS[platform]`: truncar a `LIMITS[platform] - 3` + `"..."` + log warning
    - Mergear en post: `{"platform": platform, "text": text, "source_url": item["url"], "source_title": item["title"], "score": item["score"], "generated_at": datetime.now(timezone.utc).isoformat()}`
    - Si falla los 3 retries: skip ese (item, platform), log warning, continuar con el resto
    - `log_llm_call("generate", tokens_in, tokens_out, latency_s)` por call
  - Devolver `posts` ordenados por `score` desc, luego `platform`
  - Si no hay `GEMINI_API_KEY`: raise ConfigError

  **Must NOT do**:
  - NO usar function calling
  - NO JSON mode (output es texto plano)
  - NO incluir hashtags del prompt como ejemplo (puede inducir hashtags inventados)
  - NO generar imágenes ni multimedia
  - NO incluir link de afiliado, tracking pixels, ni URLs modificadas
  - NO incluir CTAs genéricas tipo "Sígueme!" — el usuario decide eso
  - NO duplicar el sistema_instruction en el prompt de cada call

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — integración LLM con prompt design + validación de output
  - **Skills**: `[]`
  - **Skills Evaluated but Omitted**: `frontend-design` (no aplica), `seo` (no aplica directamente a posts sociales)

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (con T6, T7)
  - **Blocks**: T9 (app.py importa generator)
  - **Blocked By**: T1, T2

  **References**:
  - Plan sección "Metis Review": E (límites caracteres), 5 (prompt design)
  - Decisión usuario en entrevista: solo español, configurable vía UI
  - Límites oficiales: X=280, LinkedIn=3000, Threads=500
  - T2 helpers: `log`, `log_llm_call`

  **WHY Each Reference Matters**:
  - Truncado con warning evita posts que excedan límite y fallarían al publicar (Metis E)
  - Temperature 0.7 para generación (más creatividad) vs 0.4 para curator (más preciso)
  - Sin hashtags inventados es el #1 problema de LLMs generando social content

  **Acceptance Criteria**:
  - [ ] `from pipeline.generator import generate_posts, LIMITS` exit 0
  - [ ] `LIMITS == {"x": 280, "linkedin": 3000, "threads": 500}`
  - [ ] `generate_posts([], ["x"])` devuelve `([], "Sin noticias curadas...")`
  - [ ] `generate_posts(curated_3_items, ["x", "linkedin"])` devuelve 6 posts (3×2)
  - [ ] Todos los posts X tienen `len(text) <= 280`
  - [ ] Todos los posts LinkedIn tienen `len(text) <= 3000`
  - [ ] Posts contienen texto en español verificable
  - [ ] Sin GEMINI_API_KEY: raise excepción

  **QA Scenarios**:
  ```
  Scenario: Generate posts respeta límites de caracteres
    Tool: Bash
    Preconditions: GEMINI_API_KEY válido
    Steps:
      1. python -c "
         import asyncio
         from dotenv import load_dotenv; load_dotenv()
         from pipeline.generator import generate_posts, LIMITS
         curated = [{'title': 'Anthropic releases Claude 4 with major improvements in coding tasks', 'summary': 'Claude 4 mejora significativamente las capacidades de programación', 'url': 'https://example.com/1', 'score': 90}]
         posts, _ = asyncio.run(generate_posts(curated, ['x', 'linkedin', 'threads']))
         for p in posts:
             assert len(p['text']) <= LIMITS[p['platform']], f\"FAIL {p['platform']}: {len(p['text'])}\"
             print(f\"{p['platform']}: {len(p['text'])}/{LIMITS[p['platform']]} chars\")
         print('TOTAL:', len(posts))
         "
    Expected Result: 3 posts, todos respetan su límite, output muestra char counts
    Evidence: .sisyphus/evidence/task-8-limits.txt

  Scenario: Generator skip cuando todo input vacío
    Tool: Bash
    Steps:
      1. python -c "
         import asyncio
         from pipeline.generator import generate_posts
         p, w = asyncio.run(generate_posts([], ['x']))
         print('posts:', len(p), 'warning:', w)
         "
    Expected Result: posts: 0, warning con mensaje
    Evidence: .sisyphus/evidence/task-8-empty.txt

  Scenario: Output en español
    Tool: Bash
    Preconditions: GEMINI_API_KEY válido
    Steps:
      1. Ejecutar generate_posts con 1 noticia + plataforma X
      2. Verificar que el post contiene al menos 1 palabra común en español ("la", "el", "de", "que", "para") — usar regex
    Expected Result: matchea, output en español
    Evidence: .sisyphus/evidence/task-8-spanish.txt
  ```

  **Evidence to Capture**:
  - [ ] `.sisyphus/evidence/task-8-limits.txt`
  - [ ] `.sisyphus/evidence/task-8-empty.txt`
  - [ ] `.sisyphus/evidence/task-8-spanish.txt`

  **Commit**: YES (solo)
  - Message: `feat(pipeline): post generator per platform`
  - Files: `pipeline/generator.py`
  - Pre-commit: `python -m py_compile pipeline/generator.py`

- [x] 9. **FastAPI app + endpoints + BackgroundTasks (`app.py`)**

  **What to do**:
  - Crear `app.py` con FastAPI app, configuración y todos los endpoints
  - **Startup**: load `.env`, verificar `GEMINI_API_KEY` y log `"Gemini API key loaded: ...{key[-4:]}"` (o `"GEMINI_API_KEY no configurado — endpoints LLM devolverán 503"` si falta), crear `data/` con `mkdir(exist_ok=True)`, log `"data/ verificado"`
  - **Configuración Gemini**: `genai.configure(api_key=os.getenv("GEMINI_API_KEY"))` solo si la key existe
  - **Pydantic models**: `SourcesConfig` (subreddits: list[str], rss_feeds: list[str], hn_keywords: list[str]), `PipelineConfig` (top_n: int Field(ge=3, le=20, default=5), platforms: list[Literal["x", "linkedin", "threads"]] = ["x", "linkedin", "threads"]), modelos de respuesta
  - **Endpoints**:
    1. `GET /api/health` → `{"status": "ok"}`
    2. `GET /api/sources` → lee y valida `sources.json`, 422 con detalle si malformado
    3. `GET /api/pipeline/status` → devuelve `pipeline_state` actual
    4. `GET /api/logs` → devuelve `list(logs)` (deque convertido)
    5. `GET /api/news` → lee `news_curated.json` o `{"items": [], "warning": "..."}` si no existe
    6. `GET /api/posts` → lee `posts.json` o `{"items": []}` si no existe
    7. `POST /api/pipeline/scrape` con body `PipelineConfig` parcial (top_n irrelevante aquí) → guard concurrencia (409 si running) → set state → `BackgroundTasks` ejecuta scraper → 202
    8. `POST /api/pipeline/curate` con body `{top_n: int}` → mismo patrón, requiere `news_raw.json` exista → 503 si sin Gemini key
    9. `POST /api/pipeline/generate` con body `PipelineConfig` → requiere `news_curated.json` exista → 503 si sin Gemini key
    10. `POST /api/pipeline/run-all` con body `PipelineConfig` → ejecuta los 3 pasos secuencialmente en background → 202 → 503 si sin Gemini key
  - **Static**: `app.mount("/static", StaticFiles(directory="static"), name="static")` DESPUÉS de los `/api/*` routes
  - **Index**: `@app.get("/")` → `FileResponse("static/index.html")` (al final, para no acaparar `/api/*`)
  - **Background task functions**: `async def _run_scrape(config)`, `_run_curate(config)`, `_run_generate(config)`, `_run_all(config)` — cada una actualiza `pipeline_state` con step actual, captura excepciones, escribe outputs con `write_json`, libera `pipeline_state["running"] = False` al final (en finally)
  - **Empty results**: si scrape devuelve 0 → set warning en state, NO ejecutar siguientes pasos en `run_all`
  - **Concurrency guard**: helper `_check_not_running()` que si `pipeline_state["running"]` raise 409
  - **Gemini key guard**: helper `_check_gemini_key()` que si falta raise 503
  - **CORS**: NO instalar middleware — todo se sirve desde mismo origen

  **Must NOT do**:
  - NO WebSockets ni SSE
  - NO Celery / RQ / dramatiq
  - NO `fastapi-cors` (mismo origen)
  - NO middleware de auth (local single-user)
  - NO embed `uvicorn.run()` en el módulo (se ejecuta externamente)
  - NO bind a `0.0.0.0` por defecto
  - NO logging library (deque + print del helper de pipeline)
  - NO incluir rutas para borrar datos (`/api/clear`, etc.) — sobre-scope
  - NO retornar `200` cuando es realmente `202` (background task lanzado)

  **Recommended Agent Profile**:
  - **Category**: `deep` — orquestación, manejo de estado, error handling, secuenciación
  - **Skills**: [`nodejs-express-server`, `nodejs-backend-patterns`]
    - `nodejs-express-server`: patterns de middleware y error handling aplican a FastAPI
    - `nodejs-backend-patterns`: API design (status codes, response shapes)
  - **Skills Evaluated but Omitted**:
    - `vitest`: testing es T11 separado
    - `zod`: usamos Pydantic

  **Parallelization**:
  - **Can Run In Parallel**: NO (depende de los 3 módulos pipeline)
  - **Parallel Group**: Wave 2 (después de T6, T7, T8)
  - **Blocks**: T10 (frontend), T11 (tests API), T12 (tests UI)
  - **Blocked By**: T1, T2, T6, T7, T8

  **References**:
  - Plan sección "Metis Review": A (concurrencia 409), 9 (polling state), 10 (API key check at startup), 11 (degradación elegante sin keys), C (empty results)
  - Plan sección "Planned Endpoints" — los 11 endpoints
  - FastAPI docs: BackgroundTasks, StaticFiles, FileResponse, lifespan events
  - T6, T7, T8: módulos importados

  **WHY Each Reference Matters**:
  - Concurrency guard previene corrupción y doble consumo rate limit (Metis A)
  - 503 vs 500 distingue "config faltante" de "error real" (Metis 10)
  - Mount order: `/api/*` ANTES de static evita conflicto de rutas (Metis directiva mount ordering)
  - BackgroundTasks es la solución más simple, no necesita Celery

  **Acceptance Criteria**:
  - [ ] `python -m py_compile app.py` exit 0
  - [ ] `uvicorn app:app &` arranca sin errores, log incluye "data/ verificado"
  - [ ] `curl -sf http://localhost:8000/api/health | jq .status` → `"ok"`
  - [ ] `curl -sf http://localhost:8000/api/sources | jq .subreddits` → array
  - [ ] `curl -sf http://localhost:8000/api/pipeline/status | jq .running` → `false` (initial)
  - [ ] `curl -sf http://localhost:8000/` devuelve HTML (index.html)
  - [ ] `curl -sf http://localhost:8000/static/styles.css` devuelve 200
  - [ ] POST `/api/pipeline/run-all` cuando `pipeline_state.running=true`: 409
  - [ ] POST `/api/pipeline/curate` sin GEMINI_API_KEY: 503

  **QA Scenarios**:
  ```
  Scenario: Arranque limpio del servidor
    Tool: Bash
    Steps:
      1. uvicorn app:app --port 8765 &
      2. sleep 2
      3. curl -sf http://localhost:8765/api/health | jq -r .status
    Expected Result: "ok"
    Evidence: .sisyphus/evidence/task-9-startup.txt

  Scenario: Guard de concurrencia 409
    Tool: Bash
    Preconditions: server corriendo, GEMINI_API_KEY presente
    Steps:
      1. curl -s -X POST http://localhost:8765/api/pipeline/run-all -H "Content-Type: application/json" -d '{"top_n":3,"platforms":["x"]}' -o /dev/null -w "%{http_code}\n"  # primer → 202
      2. curl -s -X POST http://localhost:8765/api/pipeline/run-all -H "Content-Type: application/json" -d '{"top_n":3,"platforms":["x"]}' -o /dev/null -w "%{http_code}\n"  # segundo inmediato → 409
    Expected Result: primer 202, segundo 409
    Evidence: .sisyphus/evidence/task-9-concurrency.txt

  Scenario: Falta GEMINI_API_KEY devuelve 503
    Tool: Bash
    Steps:
      1. GEMINI_API_KEY="" uvicorn app:app --port 8766 &
      2. sleep 2
      3. curl -s -X POST http://localhost:8766/api/pipeline/curate -H "Content-Type: application/json" -d '{}' -o /dev/null -w "%{http_code}"
    Expected Result: "503"
    Evidence: .sisyphus/evidence/task-9-no-gemini.txt

  Scenario: Mount order correcto
    Tool: Bash
    Steps:
      1. curl -sf http://localhost:8765/api/health | jq -r .status  # NO debe servir static
      2. curl -sf http://localhost:8765/static/styles.css | head -c 10  # debe servir CSS
      3. curl -sf http://localhost:8765/ | grep -c 'col-left'  # debe servir index.html
    Expected Result: api/health = "ok", static/styles.css = CSS content, / = HTML
    Evidence: .sisyphus/evidence/task-9-mount-order.txt
  ```

  **Evidence to Capture**:
  - [ ] `.sisyphus/evidence/task-9-startup.txt`
  - [ ] `.sisyphus/evidence/task-9-concurrency.txt`
  - [ ] `.sisyphus/evidence/task-9-no-gemini.txt`
  - [ ] `.sisyphus/evidence/task-9-mount-order.txt`

  **Commit**: YES (solo)
  - Message: `feat(api): fastapi endpoints with background tasks`
  - Files: `app.py`
  - Pre-commit: `python -m py_compile app.py`

- [x] 10. **Frontend lógica reactiva (`static/app.js`)**

  **What to do**:
  - Estado local: `let pollingInterval = null; let lastLogTs = null;`
  - **On load**: `DOMContentLoaded` → ejecutar `rehydrate()`:
    1. `fetch('/api/pipeline/status').then(r=>r.json())` → si `running=true`, iniciar polling
    2. `fetch('/api/logs').then(r=>r.json())` → renderizar logs en `#log-stream`
    3. `fetch('/api/news').then(r=>r.json())` → renderizar noticias curadas en `#news-section`
    4. `fetch('/api/posts').then(r=>r.json())` → renderizar posts en `#posts-section`
    5. `fetch('/api/sources').then(...)` → log de fuentes activas (debug)
  - **Slider label dinámico**: input event en `#slider-top-n` → actualizar label con valor actual
  - **Buttons handlers**:
    - `#btn-scrape` → POST `/api/pipeline/scrape` (sin body) → si 409 mostrar mensaje en banner, si 202 iniciar polling
    - `#btn-curate` → POST `/api/pipeline/curate` con `{top_n: <slider>}` → si 503 mostrar "falta GEMINI_API_KEY"
    - `#btn-generate` → POST `/api/pipeline/generate` con `{top_n, platforms}` (platforms desde checkboxes)
    - `#btn-run-all` → POST `/api/pipeline/run-all` con full config
  - **Polling logic** (`startPolling()`):
    1. `pollingInterval = setInterval(async () => { ... }, 2000)`
    2. Cada tick: GET `/api/pipeline/status` y `/api/logs`
    3. Actualizar `#pipeline-status` con estado (e.g. `"⏳ scraping..."`, `"✅ done"`, `"❌ error"`)
    4. Append solo logs nuevos (compare con `lastLogTs`) a `#log-stream`
    5. Si `running=false`: detener polling (`clearInterval`), refrescar `/api/news` y `/api/posts`
  - **Visibility API**: `document.addEventListener('visibilitychange', ...)` → si `hidden` clear polling, si visible y running re-iniciar
  - **Copy buttons**: para cada post renderizado, botón con `data-text` → click → `navigator.clipboard.writeText(text)` → cambiar label a "Copiado!" 1.5s, luego restaurar
  - **Warning banner**: mostrar `#warning-banner` con texto si la respuesta del API incluye `warning`
  - **Error handling**: try/catch en todos los fetches, mostrar error en banner rojo
  - **NO event listener en `#nl-input`** (deshabilitado)
  - **Render functions** (`renderLogs(logs)`, `renderNews(items)`, `renderPosts(items)`) → JS plano, construye DOM con `createElement`, NO `innerHTML` con string concat de user data (XSS prevention)

  **Must NOT do**:
  - NO usar React, Vue, Svelte, Alpine, ningún framework
  - NO importar librerías externas (`import from "https://..."` prohibido)
  - NO usar `innerHTML` con strings del API (XSS) — usar `textContent` o `createElement`
  - NO acoplar polling cuando pestaña no visible (Metis directiva)
  - NO añadir lógica para `#nl-input` (sigue deshabilitado, Fase 2)
  - NO usar `localStorage` para persistir estado (servidor es source of truth)
  - NO WebSockets ni EventSource
  - NO autocomplete, suggestions, ni features no pedidos

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering` — JS plano para DOM + fetch + polling
  - **Skills**: [`accessibility`]
    - `accessibility`: focus management, aria-live para banners de status
  - **Skills Evaluated but Omitted**:
    - `vercel-react-best-practices`: NO usamos React
    - `vite`: sin build step

  **Parallelization**:
  - **Can Run In Parallel**: YES (con T11, T12)
  - **Parallel Group**: Wave 3
  - **Blocks**: T12 (Playwright tests dependen del JS funcionando)
  - **Blocked By**: T3 (HTML), T4 (CSS), T9 (endpoints)

  **References**:
  - Plan sección "Metis Review": B (rehidratación), 9 (polling logic), 6 (paral page visibility)
  - T3 `static/index.html` — IDs y estructura
  - T9 `app.py` — endpoints y shapes de respuestas
  - MDN Clipboard API, Page Visibility API

  **WHY Each Reference Matters**:
  - Rehidratación crítica para no romper UX en refresh (Metis B)
  - Polling pausado cuando tab oculto ahorra CPU (Metis 9)
  - XSS prevention: posts del LLM no deberían tener HTML pero defensa profunda

  **Acceptance Criteria**:
  - [ ] `static/app.js` existe y se sirve con status 200
  - [ ] `grep -E 'import.*http|from.*http|cdn\.|react|vue|svelte|alpine' static/app.js` exit 1
  - [ ] `grep -c 'document.addEventListener' static/app.js` ≥ 2 (DOMContentLoaded + visibilitychange)
  - [ ] Playwright test (en T12) verifica: pulsar botón → polling inicia → status cambia → posts aparecen
  - [ ] No `innerHTML` con concatenación de datos del API: `grep '\.innerHTML\s*=.*\${' static/app.js` exit 1

  **QA Scenarios**:
  ```
  Scenario: Sin imports externos
    Tool: Bash
    Steps:
      1. grep -cE 'import.*http|cdn\.|googleapis|jsdelivr' static/app.js
    Expected Result: 0
    Evidence: .sisyphus/evidence/task-10-no-imports.txt

  Scenario: Visibility API usado para pausar polling
    Tool: Bash
    Steps:
      1. grep -c 'visibilitychange' static/app.js
    Expected Result: ≥ 1
    Evidence: .sisyphus/evidence/task-10-visibility.txt

  Scenario: Funcionalidad completa via Playwright
    Tool: Playwright (skill: playwright)
    Preconditions: server corriendo, GEMINI_API_KEY válido O mock mode
    Steps:
      1. browser_navigate("http://localhost:8000/")
      2. browser_click("#btn-run-all")
      3. browser_wait_for(selector="#pipeline-status", text_contains="running", timeout=3000)
      4. browser_wait_for(selector="#pipeline-status", text_contains="done", timeout=180000)  # max 3min
      5. browser_evaluate("document.querySelectorAll('.post-card').length")  → >0
      6. browser_click(".post-card:first-child button.copy-btn")
      7. browser_wait_for(selector=".post-card:first-child button.copy-btn", text_contains="Copiado", timeout=2000)
    Expected Result: flujo completo de UI funciona end-to-end
    Evidence: .sisyphus/evidence/task-10-e2e.png (final state screenshot)
  ```

  **Evidence to Capture**:
  - [ ] `.sisyphus/evidence/task-10-no-imports.txt`
  - [ ] `.sisyphus/evidence/task-10-visibility.txt`
  - [ ] `.sisyphus/evidence/task-10-e2e.png`

  **Commit**: YES (solo)
  - Message: `feat(ui): dashboard logic with polling and copy`
  - Files: `static/app.js`
  - Pre-commit: `grep -cE 'import.*http|cdn\.' static/app.js | grep -q '^0$'`

- [x] 11. **Tests API (`tests/test_api.py`)**

  **What to do**:
  - Usar `pytest` + `httpx.AsyncClient` o `fastapi.testclient.TestClient`
  - Fixture `client` que crea TestClient con app importada
  - Fixture `client_no_gemini` que monkey-patches `os.environ` para borrar `GEMINI_API_KEY` antes de re-importar app (o usa `monkeypatch.delenv`)
  - **Smoke tests obligatorios** (mínimo 8):
    1. `test_health_returns_ok` — `GET /api/health` → 200, `{"status":"ok"}`
    2. `test_sources_endpoint_returns_valid_schema` — `GET /api/sources` → 200, contiene `subreddits`, `rss_feeds`, `hn_keywords`
    3. `test_pipeline_status_initial_state` — `GET /api/pipeline/status` → 200, `{"running": false, ...}`
    4. `test_logs_endpoint_returns_array` — `GET /api/logs` → 200, lista
    5. `test_news_endpoint_when_empty` — sin `news_curated.json`: 200, `{"items": [], "warning": ...}`
    6. `test_posts_endpoint_when_empty` — sin `posts.json`: 200, `{"items": []}`
    7. `test_missing_gemini_returns_503` — `client_no_gemini`, POST `/api/pipeline/curate` → 503, body menciona `GEMINI_API_KEY`
    8. `test_invalid_pipeline_config_returns_422` — POST `/api/pipeline/run-all` con `{"top_n": 100}` → 422 (Pydantic validation, max=20)
    9. `test_invalid_platforms_returns_422` — POST con `platforms=["facebook"]` → 422
    10. `test_index_serves_html` — `GET /` → 200, content-type html, body contiene `<title>TrendPulse`
  - **Failure modes adicionales**:
    - `test_sources_with_corrupted_json` — escribir sources.json con `{` (inválido) → GET devuelve 422 o 500 con mensaje claro (cleanup después)
  - **NO testear**: lógica interna del scraper/curator/generator (eso requiere mocks pesados, fuera de scope smoke)

  **Must NOT do**:
  - NO usar `pytest-mock` ni mocks pesados de Gemini (fuera de scope)
  - NO usar `responses` para mockear HTTP externos (smoke tests no necesitan eso)
  - NO crear `tests/__init__.py` (Metis directiva)
  - NO añadir tests de >50 líneas (deben ser smoke, no end-to-end completos)
  - NO requerir API keys reales para que los tests pasen (los que requieren skipean con skipif)
  - NO añadir `conftest.py` con fixtures complejas — fixtures locales suficientes

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — testing requiere precisión y cobertura de failure modes
  - **Skills**: [`vitest`]
    - `vitest`: aunque es pytest, patterns de TDD/smoke tests aplican
  - **Skills Evaluated but Omitted**: `nodejs-express-server` (Python no Node)

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (con T10, T12)
  - **Blocks**: F1-F4 (verification waves dependen de tests verdes)
  - **Blocked By**: T9 (endpoints existen)

  **References**:
  - Plan sección "QA Policy" — smoke tests por endpoint + failure modes
  - Plan sección "Failure Modes Obligatorios" — los 5 escenarios
  - T9 `app.py` — endpoints y shapes

  **WHY Each Reference Matters**:
  - Cobertura de failure modes evita regresiones obvias
  - Smoke vs unit: tests rápidos, cubren el contract API

  **Acceptance Criteria**:
  - [ ] `pytest tests/test_api.py -v` ejecuta y todos los tests pasan
  - [ ] Mínimo 10 tests definidos
  - [ ] `test ! -f tests/__init__.py` exit 0 (NO existe init)
  - [ ] Failure modes 1, 3, 4, 5 del plan están cubiertos (sin GEMINI, sources corrupto, doble run, empty results)
  - [ ] Test que valida 503 sin Gemini key pasa explícitamente

  **QA Scenarios**:
  ```
  Scenario: Todos los tests pasan
    Tool: Bash
    Preconditions: deps instaladas
    Steps:
      1. pytest tests/test_api.py -v --tb=short
    Expected Result: exit 0, output muestra ≥10 PASSED, 0 FAILED
    Evidence: .sisyphus/evidence/task-11-pytest.txt

  Scenario: NO existe tests/__init__.py (Metis directiva)
    Tool: Bash
    Steps:
      1. test ! -f tests/__init__.py
    Expected Result: exit 0
    Evidence: .sisyphus/evidence/task-11-no-init.txt

  Scenario: Test failure mode sin GEMINI_API_KEY pasa
    Tool: Bash
    Steps:
      1. pytest tests/test_api.py::test_missing_gemini_returns_503 -v
    Expected Result: PASSED
    Evidence: .sisyphus/evidence/task-11-503-test.txt
  ```

  **Evidence to Capture**:
  - [ ] `.sisyphus/evidence/task-11-pytest.txt`
  - [ ] `.sisyphus/evidence/task-11-no-init.txt`
  - [ ] `.sisyphus/evidence/task-11-503-test.txt`

  **Commit**: YES (solo)
  - Message: `test(api): smoke tests and failure modes`
  - Files: `tests/test_api.py`
  - Pre-commit: `pytest tests/test_api.py -v`

- [x] 12. **Tests UI Playwright (`tests/test_dashboard.py`)**

  **What to do**:
  - Usar `playwright` Python (sync API o async)
  - Fixture `server`: arrancar `uvicorn app:app --port 8765` en subprocess al inicio del módulo, terminar al final (autouse, scope="module")
  - Fixture `page`: `playwright.chromium.launch()` → `browser.new_context()` → `context.new_page()`
  - **Tests obligatorios**:
    1. `test_dashboard_loads` — navigate → verificar título "TrendPulse", 3 columnas visibles (`#col-left`, `#col-center`, `#col-right`)
    2. `test_nl_input_disabled` — verificar `#nl-input` tiene `disabled=true` y placeholder contiene "Fase 2"
    3. `test_slider_responsive` — input event en `#slider-top-n` con value=10 → label cambia
    4. `test_checkboxes_default_all_checked` — los 3 checkboxes (x, linkedin, threads) están `checked` al cargar
    5. `test_pipeline_button_visible` — `#btn-run-all` visible y enabled
    6. (Opcional, requiere keys reales) `test_pipeline_flow_e2e` — pulsa run-all → wait status running → wait done → verifica posts aparecen → wait_for_url_change innecesario. Skip si no hay GEMINI_API_KEY
    7. `test_no_console_errors` — durante la navegación inicial, no debe haber `console.error` en el browser
  - Skipif sin keys: `pytest.mark.skipif(not os.getenv("GEMINI_API_KEY"), reason="No Gemini key")`

  **Must NOT do**:
  - NO testear interacciones complejas del LLM (eso no es UI test)
  - NO testear performance / load
  - NO crear page object models (overengineering para 7 tests)
  - NO usar `time.sleep` — usar `page.wait_for_*` con timeout
  - NO depender de exactamente N posts (puede variar) — solo verificar >0

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` — Playwright requiere precisión + timing
  - **Skills**: [`playwright`]
    - `playwright`: skill especializada en browser automation
  - **Skills Evaluated but Omitted**:
    - `vitest`: tests son pytest+playwright, no vitest

  **Parallelization**:
  - **Can Run In Parallel**: YES (con T10, T11)
  - **Parallel Group**: Wave 3
  - **Blocks**: F1-F4
  - **Blocked By**: T10 (necesita JS funcional)

  **References**:
  - Plan sección "Failure Modes Obligatorios"
  - Skill `playwright` (skill embedded)
  - T3, T4, T10: HTML/CSS/JS que se testean

  **WHY Each Reference Matters**:
  - UI tests aseguran que el cambio en cualquier capa (HTML/CSS/JS) no rompa el flujo
  - Skipif evita CI rojo si no hay keys

  **Acceptance Criteria**:
  - [ ] `pytest tests/test_dashboard.py -v` ejecuta. Tests sin keys pasan, con keys el e2e pasa también
  - [ ] Mínimo 6 tests (excluyendo el opcional e2e)
  - [ ] `tests/test_dashboard.py` usa `playwright.sync_api` o `playwright.async_api`
  - [ ] Skipif para tests que requieren GEMINI_API_KEY

  **QA Scenarios**:
  ```
  Scenario: Playwright tests pasan (sin keys)
    Tool: Bash
    Preconditions: server arrancado por fixture
    Steps:
      1. playwright install chromium
      2. pytest tests/test_dashboard.py -v -m "not e2e" --tb=short
    Expected Result: exit 0, todos los non-e2e tests PASSED
    Evidence: .sisyphus/evidence/task-12-playwright-basic.txt

  Scenario: Test e2e completo con keys
    Tool: Bash
    Preconditions: GEMINI_API_KEY válido en .env
    Steps:
      1. pytest tests/test_dashboard.py::test_pipeline_flow_e2e -v --timeout=300
    Expected Result: PASSED (o SKIPPED si no hay key)
    Evidence: .sisyphus/evidence/task-12-e2e.txt
  ```

  **Evidence to Capture**:
  - [ ] `.sisyphus/evidence/task-12-playwright-basic.txt`
  - [ ] `.sisyphus/evidence/task-12-e2e.txt`

  **Commit**: YES (solo)
  - Message: `test(ui): playwright dashboard flow`
  - Files: `tests/test_dashboard.py`
  - Pre-commit: `pytest tests/test_dashboard.py -v -m "not e2e"`

---

## Final Verification Wave (MANDATORY — después de TODAS las tareas)

> 4 agentes de revisión en PARALELO. TODOS deben APROBAR. Presentar resultados consolidados al usuario y obtener "okay" explícito antes de marcar trabajo completado.
>
> **NO auto-proceder tras verificación. Esperar aprobación explícita del usuario antes de marcar trabajo completo.**
> **No marcar F1-F4 como checked antes de obtener el okay del usuario.**

- [x] F1. **Plan Compliance Audit** — `oracle`
  Leer el plan end-to-end. Para cada "Must Have": verificar implementación existe (leer archivo, curl endpoint, ejecutar comando). Para cada "Must NOT Have": grep en el codebase por patrones prohibidos — rechazar con `file:line` si encuentra. Verificar evidence files existen en `.sisyphus/evidence/`. Comparar deliverables vs plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — `unspecified-high`
  Ejecutar `python -m py_compile app.py pipeline/*.py` + `pytest`. Revisar archivos cambiados por: `# type: ignore` sin razón, `except: pass`, prints de debug, código comentado, imports sin usar, async sin necesidad. Check AI slop: comentarios excesivos, sobre-abstracción, nombres genéricos (data/result/item/temp), wrappers innecesarios. Verificar línea por línea que `pipeline/storage.py` NO existe.
  Output: `Build [PASS/FAIL] | pytest [N pass/N fail] | Files [N clean/N issues] | VERDICT`

- [x] F3. **Real Manual QA** — `unspecified-high` (+ skill `playwright`)
  Empezar de estado limpio. Ejecutar TODOS los QA scenarios de TODAS las tareas — seguir pasos exactos, capturar evidence. Probar integración cross-task: pipeline completo de extremo a extremo con keys reales (si están en `.env`, sino simular con respuestas mocked). Probar failure modes obligatorios (5 escenarios). Guardar evidence en `.sisyphus/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [PASS/FAIL] | Failure Modes [5/5] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep`
  Para cada task: leer "What to do", leer el diff real (git log/diff). Verificar 1:1 — todo lo del spec se construyó (nada falta), nada fuera del spec se construyó (nada de scope creep). Check "Must NOT do" compliance (especialmente la lista de 25+ vetos del plan). Detectar contaminación cross-task: Task N tocando archivos de Task M sin justificación. Flag cambios no contabilizados.
  Output: `Tasks [N/N compliant] | Vetos respetados [N/N] | Contaminación [CLEAN/N issues] | VERDICT`

---

## Commit Strategy

Una sola PR atómica con el pipeline completo (recomendado por Metis: "el valor sale del end-to-end funcionando"). Commits granulares dentro de la PR:

| Task | Commit message | Files |
|------|----------------|-------|
| T1 | `chore: initial config, env example, sources defaults` | `.gitignore`, `.env.example`, `sources.json`, `requirements.txt` |
| T2 | `feat(pipeline): storage helpers and shared state` | `pipeline/__init__.py` |
| T3+T4 | `feat(ui): dashboard skeleton with 3-column layout` | `static/index.html`, `static/styles.css` |
| T5 | `docs: quickstart in spanish` | `README.md` (append) |
| T6 | `feat(pipeline): scraper for reddit, hn, rss with dedup` | `pipeline/scraper.py` |
| T7 | `feat(pipeline): curator with gemini json mode` | `pipeline/curator.py` |
| T8 | `feat(pipeline): post generator per platform` | `pipeline/generator.py` |
| T9 | `feat(api): fastapi endpoints with background tasks` | `app.py` |
| T10 | `feat(ui): dashboard logic with polling and copy` | `static/app.js` |
| T11 | `test(api): smoke tests and failure modes` | `tests/test_api.py` |
| T12 | `test(ui): playwright dashboard flow` | `tests/test_dashboard.py` |

Pre-commit por task: `python -m py_compile <files>` + `pytest tests/test_api.py -k <relevant>` cuando aplique.

---

## Success Criteria

### Verification Commands

```bash
# 1. Setup
cp .env.example .env  # Editar con keys reales (Gemini + Reddit)
pip install -r requirements.txt

# 2. Tests automatizados
pytest tests/ -v
# Expected: todos verde, mínimo 5 tests de API + Playwright pasando

# 3. Manual integration con keys reales
uvicorn app:app &
SERVER_PID=$!
sleep 2

curl -sf http://localhost:8000/api/health | jq '.status'
# Expected: "ok"

curl -sf -X POST http://localhost:8000/api/pipeline/run-all \
  -H "Content-Type: application/json" \
  -d '{"top_n":3,"platforms":["x","linkedin","threads"]}' | jq '.task_started'
# Expected: true

# Esperar fin
while [ "$(curl -sf http://localhost:8000/api/pipeline/status | jq -r '.running')" = "true" ]; do
  sleep 5
done

# Validar outputs
test -f data/news_raw.json && test -f data/news_curated.json && test -f data/posts.json
cat data/posts.json | jq 'length'
# Expected: 9 (3 noticias × 3 plataformas)

cat data/posts.json | jq '.[0] | {platform, text_length: (.text | length)}'
# Expected: platform definido, text_length <= límite de plataforma

kill $SERVER_PID
```

### Final Checklist
- [ ] Todos los "Must Have" presentes (verificable por grep + curl + pytest)
- [ ] Todos los "Must NOT Have" ausentes (verificable por grep negativo y ausencia de archivos)
- [ ] `pipeline/storage.py` NO existe (Metis directiva)
- [ ] `tests/__init__.py` NO existe (Metis directiva)
- [ ] Caja "comando agéntico" en UI presente, `disabled`, con comentario `ponytail: Fase 2 only`
- [ ] Smoke tests pytest pasan
- [ ] Playwright tests pasan
- [ ] Manual integration test pasa con keys reales (o documentado por qué no se puede sin keys)
- [ ] User confirma "OKAY" tras revisar evidence files de Final Verification Wave
