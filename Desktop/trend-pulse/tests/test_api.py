"""Smoke tests for trend-pulse API endpoints."""

import pytest
from fastapi.testclient import TestClient
from app import app


@pytest.fixture
def client():
    return TestClient(app)


def test_health_returns_ok(client):
    r = client.get("/api/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_sources_endpoint_returns_valid_schema(client):
    r = client.get("/api/sources")
    assert r.status_code == 200
    data = r.json()
    assert "subreddits" in data
    assert "rss_feeds" in data
    assert "hn_keywords" in data
    assert len(data["subreddits"]) >= 3


def test_pipeline_status_initial_state(client):
    r = client.get("/api/pipeline/status")
    assert r.status_code == 200
    data = r.json()
    assert data["running"] is False


def test_logs_endpoint_returns_array(client):
    r = client.get("/api/logs")
    assert r.status_code == 200
    assert isinstance(r.json(), list)


def test_news_endpoint_when_empty(client):
    r = client.get("/api/news")
    assert r.status_code == 200
    data = r.json()
    assert "items" in data
    assert "warning" in data


def test_posts_endpoint_when_empty(client):
    r = client.get("/api/posts")
    assert r.status_code == 200
    data = r.json()
    assert "items" in data


def test_index_serves_html(client):
    r = client.get("/")
    assert r.status_code == 200
    assert "text/html" in r.headers.get("content-type", "")
    assert "TrendPulse" in r.text


def test_static_css_served(client):
    r = client.get("/static/styles.css")
    assert r.status_code == 200


def test_concurrency_guard_on_duplicate_scrape(client):
    from pipeline import pipeline_state
    pipeline_state["running"] = True
    r = client.post("/api/pipeline/scrape", json={})
    assert r.status_code == 409
    pipeline_state["running"] = False


def test_invalid_config_returns_422(client):
    r = client.post("/api/pipeline/run-all", json={"top_n": 100})
    assert r.status_code == 422


def test_invalid_platform_returns_422(client):
    r = client.post("/api/pipeline/generate", json={"top_n": 5, "platforms": ["facebook"]})
    assert r.status_code == 422


def test_pipeline_scrape_starts(client):
    r = client.post("/api/pipeline/scrape", json={})
    assert r.status_code == 200
    assert r.json()["task_started"] is True


def test_pipeline_curate_accepts_request(client):
    r = client.post("/api/pipeline/curate", json={"top_n": 5})
    assert r.status_code == 200
