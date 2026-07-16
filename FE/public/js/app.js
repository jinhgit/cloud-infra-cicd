(function () {
  const statusEl = document.getElementById("health-status");
  const bodyEl = document.getElementById("health-body");
  const base = (window.APP_CONFIG && window.APP_CONFIG.API_BASE_URL) || "";

  async function checkHealth() {
    const url = `${base.replace(/\/$/, "")}/health`;
    try {
      const res = await fetch(url, { headers: { Accept: "application/json" } });
      const data = await res.json().catch(() => ({}));
      if (res.ok) {
        statusEl.textContent = `OK (${res.status})`;
        statusEl.className = "status ok";
      } else {
        statusEl.textContent = `Error (${res.status})`;
        statusEl.className = "status bad";
      }
      bodyEl.textContent = JSON.stringify(data, null, 2);
    } catch (err) {
      statusEl.textContent = "unreachable";
      statusEl.className = "status bad";
      bodyEl.textContent = String(err.message || err);
    }
  }

  checkHealth();
})();
