# Dashboard Agéntico de Automatización de Contenidos (AI-Hub)
## Documentación Técnica del Proyecto v1.0

Este documento detalla la arquitectura, el flujo de trabajo y la hoja de ruta para la implementación de un **Dashboard de Control Agéntico**. El sistema está diseñado en una interfaz web ligera (HTML/CSS/JS) conectada a un orquestador local en Python (FastAPI). Su objetivo principal es la creación automatizada de entornos de trabajo locales, la ejecución de scrapers de Inteligencia Artificial, la curación de contenidos, la edición de boletines en Substack y la generación de guiones/vídeos cortos para redes sociales.

---

## 1. Arquitectura General del Sistema

El sistema se basa en un modelo **Híbrido de Micro-Agentes Locales** coordinados desde una interfaz centralizada.

```
+--------------------------------------------------------+
|               DASHBOARD WEB (Frontend)                 |
|       (HTML5 / Tailwind CSS / Vanilla JavaScript)       |
+---------------------------+----------------------------+
                            |
                            | HTTP / WebSockets (Fetch API)
                            v
+--------------------------------------------------------+
|              BACKEND ORQUESTRADOR (Local)              |
|                   (Python + FastAPI)                   |
+---------------------------+----------------------------+
                            |
            +---------------+---------------+
            | Function Calling / Tools API  |
            v                               v
+-----------------------+       +-----------------------+
|   LLM / CEREBRO IA    |       |   SISTEMA OPERATIVO   |
| (OpenAI / Claude API) |       |  (OS, Subprocess, CLI) |
+-----------------------+       +-----------------------+
            |                               |
            +---------------+---------------+
                            |
                            v
+--------------------------------------------------------+
|              ENTORNOS Y AGENTES ACTIVOS                |
|  [Agente Scraper] [Agente Curador] [Agente Media Dev]  |
+--------------------------------------------------------+
```

### Componentes Clave:
1. **Frontend (Torre de Control):** Una SPA (*Single Page Application*) limpia que expone el estado de los entornos, un chat agéntico para comandos de lenguaje natural y un log de eventos en tiempo real.
2. **Backend (Orquestador Local):** Servidor local seguro en FastAPI. Expone endpoints para el frontend y tiene acceso controlado al sistema de archivos local y herramientas de consola del sistema operativo (`subprocess`).
3. **Capa de Inteligencia (Function Calling):** Mapea los prompts del usuario hacia funciones ejecutables reales mediante esquemas estructurados de APIs de LLM.

---

## 2. Flujo de Trabajo del Usuario e Interacción Agéntica

El sistema opera bajo un flujo lineal estructurado en **4 fases modulares**, donde el output de una fase sirve como input automatizado para la siguiente.

```
 +------------------+      +-------------------+      +-------------------+      +-------------------+
 | FASE 1: INGESTA  |      | FASE 2: CURACIÓN  |      | FASE 3: BOLETÍN   |      | FASE 4: REDES     |
 | Scraping Semilla | ---> | Documento Maestro | ---> | Substack Engine   | ---> | Generación Cortos |
 | (RSS / Python)   |      |  (LLM Bullet Points) |    |  (Plantilla/Draft)|      | (Hooks & Scripts) |
 +------------------+      +-------------------+      +-------------------+      +-------------------+
```

### Detalle de Ejecución por Fase:

#### Fase 1: Scraping e Ingesta de Noticias de IA
* **Acción Agéntica:** El sistema levanta un script supervisor cronometrado o disparado por demanda.
* **Fuentes Semilla Iniciales:** *TechCrunch AI*, *MIT Technology Review*, *r/MachineLearning*, *TLDR AI*, *Hacker News*.
* **Procesamiento:** Almacenamiento crudo indexando `Título`, `URL`, `Fecha` y `Contenido Original` en una base de datos o JSON local plano, aplicando un script de deduplicación basado en hashes de URLs.

#### Fase 2: Curación y Creación del Documento Maestro
* **Acción Agéntica:** El agente lee las entradas de la Fase 1 y las procesa en paralelo usando prompts refinados de análisis conceptual.
* **Estructura del Output:** Cada noticia se reduce a 3 ejes fundamentales:
    1.  *¿Qué es?* (Definición técnica o de producto).
    2.  *¿Por qué importa?* (Impacto en el ecosistema).
    3.  *¿Cómo afecta al sector?* (Implicaciones de negocio).
* **Supervisión Humana:** El Dashboard retiene el archivo en estado `Draft` (Borrador) para permitir la revisión, edición de alucinaciones y personalización de la línea editorial del usuario.

#### Fase 3: Newsletter en Substack
* **Acción Agéntica:** Al activar el envío del documento de la Fase 2, el orquestador compila los bloques usando una estructura modular predefinida.
* **Secciones del Boletín:**
    * *El Gran Titular:* Análisis profundo del hito de la semana.
    * *Píldoras Rápidas:* 3 a 5 resúmenes ejecutivos curados de la fase anterior.
    * *La Herramienta de la Semana:* Enlace práctico e instrucciones de testeo rápido.
* **Distribución:** Preparación automática del contenido listo para ser inyectado vía portapapeles o mediante llamadas simuladas/API a borradores de Substack.

#### Fase 4: Vídeos Cortos para Redes Sociales (TikTok, Reels, Shorts)
* **Acción Agéntica:** El Agente de Contenidos Multimedia toma la noticia mejor valorada o el "Gran Titular" y redacta guiones optimizados para retención en formato vertical (9:16).
* **Fórmula de Retención Utilizada:**
    * *0-3 segundos (Hook):* Patrón de interrupción disruptivo en texto y voz.
    * *3-20 segundos (Cuerpo):* Desarrollo dinámico del problema técnico o lanzamiento.
    * *20-30 segundos (CTA):* Redirección imperativa al link de la biografía para leer el newsletter completo.
* **Automatización de Render:** El orquestador interactúa con herramientas CLI o APIs de procesamiento (como CapCut local o librerías de Python como `MoviePy` / subtitulado automatizado con `Whisper`) para generar una base pre-editada.

---

## 3. Especificación de la Interfaz del Dashboard (Frontend)

El Frontend se compone de un único archivo `index.html`, un archivo de estilos rápidos asistido por clases utilitarias de Tailwind y un archivo de lógica reactiva `app.js` en Vanilla JavaScript.

### Estructura de Módulos Visuales (Layout Grid):

1.  **Panel de Agentes y Control de Entornos (Izquierda - 25% width):**
    * Interruptores de estado para el Scraper automático.
    * Métricas del sistema (Estado de APIs, consumo local).
    * Botón dinámico `+ Crear Nuevo Entorno`.
2.  **Consola Agéntica Central (Centro - 50% width):**
    * Historial de logs estilo terminal que muestra las acciones en tiempo real de los agentes activos (ej: `[AGENTE-DEVOPS] Creando directorio /proyectos/news-scraper-01...`).
    * Caja de comandos en lenguaje natural: *"Crea un entorno de scraping enfocado en LLMs locales"*.
3.  **Explorador de Entornos y Outputs (Derecha - 25% width):**
    * Lista de carpetas generadas.
    * Accesos directos para abrir directorios en editores de código (ej. VS Code mediante el protocolo `vscode://file/`).
    * Enlaces rápidos a los documentos maestros de la Fase 2 generados localmente.

---

## 4. Implementación del Backend y Automatización DevOps

El backend se ejecuta localmente y expone servicios del sistema operativo de manera controlada.

### Ejemplo de Estructura de Endpoints de Control:
* `POST /api/agent/command`: Recibe el prompt de lenguaje natural. Lo parsea usando OpenAI Function Calling para determinar la acción (ej: `crear_entorno`).
* `GET /api/environments`: Devuelve la lista de entornos de desarrollo creados en el disco local.
* `POST /api/scraper/run`: Dispara de forma síncrona o asíncrona la ejecución de las arañas de extracción de datos.

### Lógica de Creación de Entornos Locales (Sandbox):
Cuando el agente determina la acción de crear un entorno, ejecuta de forma encadenada bajo un proceso seguro:
1.  Creación física del directorio bajo una ruta raíz controlada (`mkdir -p /proyectos/{nombre_proyecto}`).
2.  Inicialización de entornos virtuales aislados de desarrollo (`python3 -m venv venv`).
3.  Escritura de plantillas base (archivos `scraper.py`, `requirements.txt` pre-configurados).
4.  Retorno de un payload JSON con el estatus detallado de los puertos asignados y rutas físicas para su renderizado inmediato en el dashboard.

---

## 5. Hoja de Ruta de Implementación (Fases de Desarrollo)

Para asegurar la estabilidad del software y evitar fallos por sobreingeniería, el desarrollo se divide en un despliegue incremental y estructurado:

### Semana 1-2: Fase del Motor y Cableado Técnico (Prioridad Máxima)
* Desarrollar la interfaz HTML/CSS/JS base sin integración de Inteligencia Artificial.
* Programar el backend en FastAPI con endpoints estáticos y cableado directo al sistema operativo.
* **Meta:** Validar que al presionar un botón del dashboard, se cree físicamente una carpeta con archivos en el disco y se refleje en el panel de control.

### Semana 3-4: Fase Intelectual (Integración del Cerebro de IA)
* Vincular el cuadro de texto del Dashboard al backend conectado a la API del LLM.
* Implementar esquemas de *Function Calling* / *Tools* para traducir peticiones libres (*"Créame un entorno..."*) en comandos lógicos precisos.
* Estructurar los scripts base de scraping de noticias e implementar prompts de curación analítica en 3 viñetas.

### Semana 5+: Fase de Distribución Multimedia y Escalamiento
* Habilitar el compilador modular de newsletters hacia Substack.
* Integrar los generadores agénticos de guiones de vídeo en base al boletín semanal.
* Automatizar mediante código los flujos de renderizado, inserción de clips de apoyo y subtitulado dinámico de shorts verticales.

---

## Quickstart (Fase 1)

> Pipeline agentic de contenido corto: scrapea noticias IA → curan con Gemini → genera posts cortos en español para X / LinkedIn / Threads.

### Requisitos
- Python 3.11 o superior
- Cuenta gratuita en Google AI Studio (Gemini): https://aistudio.google.com/app/apikey
- Cuenta Reddit + app registrada como "script": https://www.reddit.com/prefs/apps

### Instalación
```bash
git clone <repo>
cd trend-pulse
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Editar .env con las 3 keys (links en el archivo)
```

### Ejecución
```bash
uvicorn app:app
# Abrir http://localhost:8000
```

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
