(function () {
  const healthStatusEl = document.getElementById("health-status");
  const healthBodyEl = document.getElementById("health-body");
  const helloStatusEl = document.getElementById("hello-status");
  const helloBodyEl = document.getElementById("hello-body");
  const infoStatusEl = document.getElementById("info-status");
  const infoBodyEl = document.getElementById("info-body");
  const metaEl = document.getElementById("runtime-meta");

  const base = ((window.APP_CONFIG && window.APP_CONFIG.API_BASE_URL) || "").replace(
    /\/$/,
    ""
  );

  function apiUrl(path) {
    if (!path.startsWith("/")) path = "/" + path;
    return base + path;
  }

  async function fetchJson(path) {
    const res = await fetch(apiUrl(path), {
      headers: { Accept: "application/json" },
    });
    const data = await res.json().catch(() => ({}));
    return { res, data };
  }

  function setStatus(el, ok, text) {
    if (!el) return;
    el.textContent = text;
    el.className = "status " + (ok ? "ok" : "bad");
  }

  async function checkHealth() {
    try {
      const { res, data } = await fetchJson("/health");
      if (res.ok && data.status === "ok") {
        setStatus(healthStatusEl, true, `OK (${res.status})`);
      } else {
        setStatus(healthStatusEl, false, `Error (${res.status})`);
      }
      healthBodyEl.textContent = JSON.stringify(data, null, 2);
    } catch (err) {
      setStatus(healthStatusEl, false, "unreachable");
      healthBodyEl.textContent = String(err.message || err);
    }
  }

  async function checkHello() {
    try {
      const { res, data } = await fetchJson("/api/hello");
      setStatus(helloStatusEl, res.ok, res.ok ? `OK (${res.status})` : `Error (${res.status})`);
      helloBodyEl.textContent = JSON.stringify(data, null, 2);
    } catch (err) {
      setStatus(helloStatusEl, false, "unreachable");
      helloBodyEl.textContent = String(err.message || err);
    }
  }

  async function checkInfo() {
    try {
      const { res, data } = await fetchJson("/api/info");
      setStatus(infoStatusEl, res.ok, res.ok ? `OK (${res.status})` : `Error (${res.status})`);
      infoBodyEl.textContent = JSON.stringify(data, null, 2);
      if (res.ok && metaEl) {
        const ver = data.version || "?";
        const sha = data.gitSha || data.git_sha || "dev";
        metaEl.textContent =
          (base ? `API_BASE_URL=${base} · ` : "same-origin · ") +
          `BE v${ver} @ ${sha}`;
      }
    } catch (err) {
      setStatus(infoStatusEl, false, "unreachable");
      if (infoBodyEl) infoBodyEl.textContent = String(err.message || err);
    }
  }

  if (metaEl && !metaEl.textContent) {
    metaEl.textContent = base
      ? `API_BASE_URL = ${base}`
      : "API_BASE_URL = (same-origin)";
  }

  function refresh() {
    if (healthStatusEl) {
      healthStatusEl.textContent = "checking…";
      healthStatusEl.className = "status pending";
    }
    if (helloStatusEl) {
      helloStatusEl.textContent = "checking…";
      helloStatusEl.className = "status pending";
    }
    if (infoStatusEl) {
      infoStatusEl.textContent = "checking…";
      infoStatusEl.className = "status pending";
    }
    checkInfo();
    checkHealth();
    checkHello();
  }

  document.getElementById("btn-refresh")?.addEventListener("click", refresh);
  refresh();
})();
