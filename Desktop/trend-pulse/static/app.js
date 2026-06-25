// static/app.js — Dashboard logic for trend-pulse

let pollingInterval = null;
let lastLogCount = 0;

document.addEventListener("DOMContentLoaded", () => {
  // Slider label sync
  const slider = document.getElementById("slider-top-n");
  const sliderLabel = document.getElementById("slider-value");
  slider.addEventListener("input", () => {
    sliderLabel.textContent = slider.value;
  });

  // Button handlers
  document.getElementById("btn-scrape").addEventListener("click", () => startPipeline("scrape", {}));
  document.getElementById("btn-curate").addEventListener("click", () => startPipeline("curate", { top_n: +slider.value }));
  document.getElementById("btn-generate").addEventListener("click", () => startPipeline("generate", getConfig()));
  document.getElementById("btn-run-all").addEventListener("click", () => startPipeline("run-all", getConfig()));

  // Rehydrate on load
  fetchStatus();
  fetchLogs();
  fetchNews();
  fetchPosts();

  // Visibility API: pause polling when tab hidden
  document.addEventListener("visibilitychange", () => {
    if (document.hidden && pollingInterval) {
      clearInterval(pollingInterval);
      pollingInterval = null;
    } else if (!document.hidden) {
      fetchStatus(); // re-check and restart if needed
    }
  });
});

function getConfig() {
  const slider = document.getElementById("slider-top-n");
  const checkboxes = document.querySelectorAll("#platforms-fieldset input[type=checkbox]:checked");
  return {
    top_n: +slider.value,
    platforms: Array.from(checkboxes).map(cb => cb.value),
  };
}

async function startPipeline(step, body) {
  try {
    const res = await fetch(`/api/pipeline/${step}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    if (res.status === 409) {
      showWarning("Pipeline ya en curso");
      return;
    }
    if (res.status === 503) {
      const data = await res.json();
      showWarning(data.detail || "Falta GEMINI_API_KEY en .env");
      return;
    }
    const data = await res.json();
    if (data.task_started) {
      startPolling();
    }
  } catch (err) {
    showWarning("Error al iniciar pipeline: " + err.message);
  }
}

function startPolling() {
  if (pollingInterval) return;
  pollingInterval = setInterval(async () => {
    const statusRes = await fetch("/api/pipeline/status");
    const status = await statusRes.json();
    updateStatus(status);

    await fetchLogs();

    if (!status.running && status.step === "done") {
      clearInterval(pollingInterval);
      pollingInterval = null;
      fetchNews();
      fetchPosts();
    }
  }, 2000);
}

function updateStatus(status) {
  const el = document.getElementById("pipeline-status");
  if (status.running) {
    el.innerHTML = `⏳ ${status.step || "trabajando"}${status.progress ? " — " + status.progress : ""}`;
  } else if (status.error) {
    el.innerHTML = `❌ Error: ${status.error}`;
    showWarning(status.error);
  } else if (status.warning) {
    el.innerHTML = `⚠️ ${status.warning}`;
    showWarning(status.warning);
  } else if (status.finished_at) {
    el.innerHTML = "✅ Completado";
  } else {
    el.innerHTML = "Inactivo";
  }
}

function showWarning(msg) {
  const banner = document.getElementById("warning-banner");
  banner.textContent = msg;
  banner.hidden = false;
  setTimeout(() => { banner.hidden = true; }, 8000);
}

async function fetchStatus() {
  const res = await fetch("/api/pipeline/status");
  const status = await res.json();
  updateStatus(status);
  if (status.running) startPolling();
}

async function fetchLogs() {
  try {
    const res = await fetch("/api/logs");
    const logs = await res.json();
    const stream = document.getElementById("log-stream");
    if (logs.length > lastLogCount) {
      const newLogs = logs.slice(lastLogCount);
      for (const entry of newLogs) {
        stream.appendChild(createLogEntry(entry));
      }
      lastLogCount = logs.length;
      stream.scrollTop = stream.scrollHeight;
    }
  } catch (e) { /* ignore */ }
}

function createLogEntry(entry) {
  const div = document.createElement("div");
  const time = entry.ts ? entry.ts.slice(11, 19) : "";
  const level = entry.level || "info";
  const color = level === "error" ? "#ef4444" : level === "warning" ? "#f59e0b" : "#94a3b8";
  div.style.color = color;
  div.textContent = `[${time}] [${level.toUpperCase()}] ${entry.msg}`;
  return div;
}

async function fetchNews() {
  try {
    const res = await fetch("/api/news");
    const data = await res.json();
    const list = document.getElementById("news-list");
    list.innerHTML = "";
    if (data.warning) {
      const w = document.createElement("p");
      w.textContent = data.warning;
      w.style.color = "#f59e0b";
      list.appendChild(w);
      return;
    }
    for (const item of data.items || []) {
      const card = document.createElement("div");
      card.className = "card";
      card.innerHTML = `
        <div class="card-title">${escapeHtml(item.title || "")}</div>
        <div class="card-meta">Score: ${item.score || 0}</div>
        <div class="card-body">${escapeHtml(item.summary || "")}</div>
      `;
      list.appendChild(card);
    }
  } catch (e) { /* ignore */ }
}

async function fetchPosts() {
  try {
    const res = await fetch("/api/posts");
    const data = await res.json();
    const list = document.getElementById("posts-list");
    list.innerHTML = "";
    for (const post of data.items || []) {
      const card = document.createElement("div");
      card.className = "card post-card";
      card.innerHTML = `
        <div class="card-meta">${post.platform} · Score: ${post.score}</div>
        <div class="card-body">${escapeHtml(post.text || "")}</div>
        <button class="copy-btn" data-text="${escapeAttr(post.text || "")}">Copiar</button>
      `;
      card.querySelector(".copy-btn").addEventListener("click", async (e) => {
        const btn = e.currentTarget;
        const text = btn.dataset.text;
        try {
          await navigator.clipboard.writeText(text);
          btn.textContent = "Copiado!";
          setTimeout(() => { btn.textContent = "Copiar"; }, 1500);
        } catch (err) {
          btn.textContent = "Error";
        }
      });
      list.appendChild(card);
    }
  } catch (e) { /* ignore */ }
}

function escapeHtml(str) {
  const div = document.createElement("div");
  div.textContent = str;
  return div.innerHTML;
}

function escapeAttr(str) {
  return str.replace(/"/g, "&quot;").replace(/'/g, "&#39;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}
