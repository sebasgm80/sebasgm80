import asyncio
import json
import os

from pipeline import log, log_llm_call

try:
    import google.generativeai as genai
except ImportError:
    genai = None  # will be checked at call time


async def curate(items: list[dict], top_n: int = 5) -> tuple[list[dict], str | None]:
    """Rank and summarize news items using Gemini Flash. Returns (curated_items, warning_message)."""
    if not items:
        return [], "Sin noticias para curar"

    api_key = os.getenv("GEMINI_API_KEY", "")
    if not api_key:
        raise ValueError("GEMINI_API_KEY no configurada")

    if genai is None:
        raise ImportError("google-generativeai no instalado")

    genai.configure(api_key=api_key)

    model = genai.GenerativeModel(
        model_name="gemini-2.0-flash",
        system_instruction=(
            "Eres un editor experto en noticias de inteligencia artificial. "
            "Tu trabajo es rankear las noticias por relevancia (impacto técnico, novedad, audiencia profesional), "
            "y resumir cada una en 2-3 frases en español neutro."
        ),
        generation_config={
            "response_mime_type": "application/json",
            "temperature": 0.4,
        },
    )

    # Build prompt with titles only (save tokens)
    titles_text = "\n".join(
        f"[{i}] {item.get('title', 'sin título')}"
        for i, item in enumerate(items)
    )

    prompt = (
        f"Rankea estas {len(items)} noticias de IA por relevancia (0-100). "
        f"Devuelve un JSON array: [{{\"index\": int, \"score\": int (0-100), \"summary\": \"resumen en español\"}}, ...]\n\n"
        f"Noticias:\n{titles_text}"
    )

    # Rate limit: 4.1s between calls for 15 RPM
    await asyncio.sleep(4.1)

    last_error = None
    for attempt in range(3):
        try:
            import time
            t0 = time.time()
            response = await model.generate_content_async(prompt)
            latency = time.time() - t0

            # Log LLM call
            try:
                log_llm_call(
                    "curate",
                    response.usage_metadata.prompt_token_count,
                    response.usage_metadata.candidates_token_count,
                    latency,
                )
            except Exception:
                pass

            # Parse JSON response
            text = response.text.strip()
            # Strip markdown code blocks if present
            if text.startswith("```"):
                text = text.split("\n", 1)[1] if "\n" in text else text
                text = text.rsplit("```", 1)[0] if "```" in text else text
                text = text.strip()

            rankings = json.loads(text)

            # Merge scores and summaries back into items
            ranked = []
            for r in rankings:
                idx = r.get("index")
                if 0 <= idx < len(items):
                    item = dict(items[idx])
                    item["score"] = r.get("score", 0)
                    item["summary"] = r.get("summary", "")
                    ranked.append(item)

            # Sort by score descending, take top_n
            ranked.sort(key=lambda x: x.get("score", 0), reverse=True)
            result = ranked[:top_n]

            log("info", f"Curated: {len(result)}/{len(items)} items (top {top_n})")
            return result, None

        except json.JSONDecodeError as e:
            last_error = f"Error parsing JSON from Gemini: {e}"
            log("warning", last_error)
            if attempt < 2:
                await asyncio.sleep(2 ** attempt)
                continue
        except Exception as e:
            last_error = f"Gemini error: {e}"
            log("warning", last_error)
            if attempt < 2 and "429" in str(e):
                await asyncio.sleep(2 ** attempt)
                continue
            break

    # Fallback: return scored items by existing score
    log("warning", f"Curate failed after retries: {last_error}. Returning unscored.")
    sorted_items = sorted(items, key=lambda x: x.get("score", 0), reverse=True)
    return sorted_items[:top_n], last_error
