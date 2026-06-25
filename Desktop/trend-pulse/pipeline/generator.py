import asyncio
import json
import os
from datetime import datetime, timezone

from pipeline import log, log_llm_call

try:
    import google.generativeai as genai
except ImportError:
    genai = None

LIMITS = {"x": 280, "linkedin": 3000, "threads": 500}


async def generate_posts(curated: list[dict], platforms: list[str]) -> tuple[list[dict], str | None]:
    if not curated:
        return [], "Sin noticias curadas para generar posts"
    if not platforms:
        return [], "Sin plataformas seleccionadas"

    api_key = os.getenv("GEMINI_API_KEY", "")
    if not api_key:
        raise ValueError("GEMINI_API_KEY no configurada")

    if genai is None:
        raise ImportError("google-generativeai no instalado")

    genai.configure(api_key=api_key)

    model = genai.GenerativeModel(
        model_name="gemini-2.0-flash",
        system_instruction=(
            "Eres un editor de redes sociales experto. Generas posts cortos en español, "
            "claros y enganchadores, sin hashtags inventados, sin emojis excesivos, "
            "sin inventar datos. Adaptas el tono a la plataforma."
        ),
        generation_config={"temperature": 0.7},
    )

    posts = []
    total = len(curated) * len(platforms)
    done = 0

    for item in curated:
        for platform in platforms:
            max_chars = LIMITS.get(platform, 500)

            prompt = (
                f"Genera un post para {platform} (máx {max_chars} caracteres) sobre esta noticia. "
                f"Mantén el tono profesional pero accesible. Incluye 1 emoji solo si aporta. "
                f"No uses hashtags inventados (puedes usar 1-2 hashtags reales del tema).\n\n"
                f"Título: {item.get('title', '')}\n"
                f"Resumen: {item.get('summary', '')}\n"
                f"URL: {item.get('url', '')}\n\n"
                f"Devuelve SOLO el texto del post, sin explicaciones."
            )

            await asyncio.sleep(4.1)

            text = None
            last_error = None

            for attempt in range(3):
                try:
                    import time
                    t0 = time.time()
                    response = await model.generate_content_async(prompt)
                    latency = time.time() - t0

                    try:
                        log_llm_call("generate",
                                     response.usage_metadata.prompt_token_count,
                                     response.usage_metadata.candidates_token_count,
                                     latency)
                    except Exception:
                        pass

                    text = response.text.strip()
                    if text.startswith("```"):
                        text = text.split("\n", 1)[1] if "\n" in text else text
                        text = text.rsplit("```", 1)[0] if "```" in text else text
                        text = text.strip()

                    if len(text) > max_chars:
                        text = text[: max_chars - 3] + "..."
                        log("warning", f"Post truncated for {platform} ({len(text)}>{max_chars})")

                    break

                except Exception as e:
                    last_error = str(e)
                    log("warning", f"Generate error ({platform}/{attempt}): {e}")
                    if attempt < 2 and "429" in str(e):
                        await asyncio.sleep(2 ** attempt)
                    else:
                        break

            if text:
                posts.append({
                    "platform": platform,
                    "text": text,
                    "source_url": item.get("url", ""),
                    "source_title": item.get("title", ""),
                    "score": item.get("score", 0),
                    "generated_at": datetime.now(timezone.utc).isoformat(),
                })
                done += 1
            else:
                log("warning", f"Failed to generate post for {platform}: {last_error}")

    posts.sort(key=lambda p: (-p.get("score", 0), p.get("platform", "")))

    log("info", f"Generated {len(posts)}/{total} posts")
    return posts, None
