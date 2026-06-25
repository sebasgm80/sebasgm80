"""Playwright UI tests for trend-pulse dashboard."""

import os
import subprocess
import time
import signal
from pathlib import Path

import pytest

pytest.importorskip("playwright")
from playwright.sync_api import sync_playwright


@pytest.fixture(scope="module")
def server():
    """Start uvicorn server for tests."""
    proc = subprocess.Popen(
        ["uvicorn", "app:app", "--port", "8765"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    time.sleep(2)
    yield
    proc.terminate()
    proc.wait()


@pytest.fixture
def page(server):
    with sync_playwright() as p:
        browser = p.chromium.launch()
        ctx = browser.new_context()
        page = ctx.new_page()
        yield page
        browser.close()


def test_dashboard_loads(page):
    page.goto("http://localhost:8765")
    assert "TrendPulse" in page.title()
    assert page.locator("#col-left").is_visible()
    assert page.locator("#col-center").is_visible()
    assert page.locator("#col-right").is_visible()


def test_nl_input_disabled(page):
    page.goto("http://localhost:8765")
    nl_input = page.locator("#nl-input")
    assert nl_input.is_disabled()
    placeholder = nl_input.get_attribute("placeholder")
    assert placeholder and "Fase 2" in placeholder


def test_slider_default_value(page):
    page.goto("http://localhost:8765")
    slider = page.locator("#slider-top-n")
    assert slider.input_value() == "5"
    label = page.locator("#slider-value")
    assert label.text_content() == "5"


def test_checkboxes_default_all_checked(page):
    page.goto("http://localhost:8765")
    for value in ["x", "linkedin", "threads"]:
        cb = page.locator(f'input[type="checkbox"][value="{value}"]')
        assert cb.is_checked()


def test_pipeline_buttons_visible(page):
    page.goto("http://localhost:8765")
    assert page.locator("#btn-scrape").is_enabled()
    assert page.locator("#btn-curate").is_enabled()
    assert page.locator("#btn-generate").is_enabled()
    assert page.locator("#btn-run-all").is_enabled()


def test_no_console_errors(page):
    errors = []
    page.on("console", lambda msg: errors.append(msg) if msg.type == "error" else None)
    page.goto("http://localhost:8765")
    assert len(errors) == 0, f"Console errors: {errors}"
