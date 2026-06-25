import asyncio
from datetime import datetime, timezone
import os

import httpx
import feedparser

from pipeline import log, add_seen_url, is_seen

async def scrape_all(sources: dict) -> list[dict]:
    """
    Execute all scrapers in parallel and return deduplicated combined results.
    sources dict has: {"subreddits": [...], "rss_feeds": [...], "hn_keywords": [...]}
    """
    async with httpx.AsyncClient(timeout=30.0) as client:
        results = await asyncio.gather(
            scrape_reddit(client, sources.get("subreddits", [])),
            scrape_hn(client, sources.get("hn_keywords", []), max_ids=120),
            scrape_rss(sources.get("rss_feeds", [])),
            return_exceptions=True,
        )
    
    all_items = []
    for result in results:
        if isinstance(result, Exception):
            log("warning", f"Scraper error: {result}")
            continue
        all_items.extend(result)
    
    # Dedup within batch (same run)
    seen = set()
    deduped = []
    for item in all_items:
        url = item.get("url", "")
        if url and url not in seen:
            seen.add(url)
            deduped.append(item)
    
    # Filter by persistent seen_urls
    new_items = [item for item in deduped if not is_seen(item.get("url", ""))]
    
    # Mark as seen
    for item in new_items:
        add_seen_url(item.get("url", ""))
    
    log("info", f"Scraping complete: {len(deduped)} items ({len(new_items)} new)")
    return new_items


async def scrape_reddit(client: httpx.AsyncClient, subreddits: list[str]) -> list[dict]:
    """Scrape Reddit hot posts for given subreddits via OAuth API."""
    if not subreddits:
        return []
    
    client_id = os.getenv("REDDIT_CLIENT_ID", "")
    client_secret = os.getenv("REDDIT_CLIENT_SECRET", "")
    user_agent = os.getenv("REDDIT_USER_AGENT", "trend-pulse-bot/0.1")
    
    if not client_id or not client_secret:
        log("warning", "Reddit creds missing, skipping Reddit")
        return []
    
    # Get OAuth token (one-shot per run)
    auth_resp = await client.post(
        "https://www.reddit.com/api/v1/access_token",
        auth=(client_id, client_secret),
        data={"grant_type": "client_credentials"},
        headers={"User-Agent": user_agent},
    )
    auth_resp.raise_for_status()
    token = auth_resp.json()["access_token"]
    
    items = []
    headers = {"Authorization": f"Bearer {token}", "User-Agent": user_agent}
    
    for sub in subreddits:
        try:
            resp = await client.get(
                f"https://oauth.reddit.com/r/{sub}/hot.json?limit=25",
                headers=headers,
            )
            resp.raise_for_status()
            posts = resp.json()["data"]["children"]
            
            for post in posts:
                p = post["data"]
                items.append({
                    "source": "reddit",
                    "subreddit": sub,
                    "title": p["title"],
                    "url": p["url"],
                    "score": p["score"],
                    "created_utc": p["created_utc"],
                })
            log("info", f"Scraping reddit/{sub}: {len(posts)} items")
        except Exception as e:
            log("warning", f"Reddit/{sub} error: {e}")
    
    return items


async def scrape_hn(client: httpx.AsyncClient, keywords: list[str], max_ids: int = 120) -> list[dict]:
    """Scrape Hacker News top stories filtered by keywords."""
    if not keywords:
        return []
    
    try:
        resp = await client.get("https://hacker-news.firebaseio.com/v0/topstories.json")
        resp.raise_for_status()
        story_ids = resp.json()[:max_ids]
    except Exception as e:
        log("warning", f"HN topstories error: {e}")
        return []
    
    # Fetch items in batches with semaphore
    sem = asyncio.Semaphore(20)
    
    async def fetch_item(item_id):
        async with sem:
            try:
                r = await client.get(f"https://hacker-news.firebaseio.com/v0/item/{item_id}.json")
                return r.json()
            except:
                return None
    
    items = []
    fetched = await asyncio.gather(*[fetch_item(i) for i in story_ids])
    
    keywords_lower = [k.lower() for k in keywords]
    
    for item in fetched:
        if not item or item.get("type") != "story":
            continue
        title = (item.get("title") or "")
        if any(kw in title.lower() for kw in keywords_lower):
            items.append({
                "source": "hn",
                "title": title,
                "url": item.get("url") or f"https://news.ycombinator.com/item?id={item['id']}",
                "score": item.get("score", 0),
                "created_utc": item.get("time", 0),
            })
    
    log("info", f"Scraping HN: {len(items)} matches from {len(story_ids)} stories")
    return items


def scrape_rss(feed_urls: list[str]) -> list[dict]:
    """Scrape RSS feeds synchronously with feedparser."""
    if not feed_urls:
        return []
    
    items = []
    for url in feed_urls:
        try:
            feed = feedparser.parse(url)
            for entry in feed.entries[:20]:
                published = entry.get("published_parsed")
                created = datetime(*published[:6], tzinfo=timezone.utc).timestamp() if published else datetime.now(timezone.utc).timestamp()
                items.append({
                    "source": "rss",
                    "feed": url,
                    "title": entry.get("title", ""),
                    "url": entry.get("link", ""),
                    "score": 0,
                    "created_utc": created,
                })
            log("info", f"Scraping RSS {url}: {len(feed.entries[:20])} items")
        except Exception as e:
            log("warning", f"RSS {url} error: {e}")
    
    return items
