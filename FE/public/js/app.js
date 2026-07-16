(function () {
  const healthStatusEl = document.getElementById("health-status");
  const healthBodyEl = document.getElementById("health-body");
  const helloStatusEl = document.getElementById("hello-status");
  const helloBodyEl = document.getElementById("hello-body");
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
      if (res.ok) {
        setStatus(helloStatusEl, true, `OK (${res.status})`);
      } else {
        setStatus(helloStatusEl, false, `Error (${res.status})`);
      }
      helloBodyEl.textContent = JSON.stringify(data, null, 2);
    } catch (err) {
      setStatus(helloStatusEl, false, "unreachable");
      helloBodyEl.textContent = String(err.message || err);
    }
  }

  if (metaEl) {
    metaEl.textContent = base
      ? `API_BASE_URL = ${base}`
      : "API_BASE_URL = (same-origin)";
  }

  document.getElementById("btn-refresh")?.addEventListener("click", () => {
    healthStatusEl.textContent = "checking…";
    healthStatusEl.className = "status pending";
    helloStatusEl.textContent = "checking…";
    helloStatusEl.className = "status pending";
    checkHealth();
    checkHello();
  });

  checkHealth();
  checkHello();
})();
