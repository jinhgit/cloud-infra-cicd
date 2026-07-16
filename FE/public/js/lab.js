(function () {
  const liveStatus = document.getElementById("live-status");
  const liveBody = document.getElementById("live-body");
  const btn = document.getElementById("btn-live");

  const KEY = "cloud-infra-lab-checks";

  function loadChecks() {
    try {
      return JSON.parse(localStorage.getItem(KEY) || "{}");
    } catch {
      return {};
    }
  }

  function saveChecks(map) {
    localStorage.setItem(KEY, JSON.stringify(map));
  }

  function bindCheckboxes() {
    const saved = loadChecks();
    document.querySelectorAll('.check-list input[type="checkbox"]').forEach((el) => {
      if (saved[el.id]) el.checked = true;
      el.addEventListener("change", () => {
        const m = loadChecks();
        m[el.id] = el.checked;
        saveChecks(m);
      });
    });
  }

  async function liveCheck() {
    liveStatus.textContent = "checking…";
    liveStatus.className = "status pending";
    const lines = [];
    let allOk = true;

    async function hit(path) {
      try {
        const res = await fetch(path, { headers: { Accept: "application/json" } });
        const text = await res.text();
        let body = text;
        try {
          body = JSON.stringify(JSON.parse(text), null, 2);
        } catch {
          /* plain */
        }
        lines.push(`${path} → HTTP ${res.status}\n${body}`);
        return res.ok;
      } catch (e) {
        lines.push(`${path} → ERROR ${e.message}`);
        return false;
      }
    }

    const fe = await hit("/healthz");
    const health = await hit("/health");
    const hello = await hit("/api/hello");
    allOk = fe && health && hello;

    liveBody.textContent = lines.join("\n\n");
    if (allOk) {
      liveStatus.textContent = "로컬 앱 전부 OK — 홈/API 정상";
      liveStatus.className = "status ok";
      ["c-fe", "c-be", "c-hello"].forEach((id) => {
        const el = document.getElementById(id);
        if (el) {
          el.checked = true;
          const m = loadChecks();
          m[id] = true;
          saveChecks(m);
        }
      });
    } else {
      liveStatus.textContent =
        "일부 실패 — docker compose up --build 후 다시 시도";
      liveStatus.className = "status bad";
    }
  }

  btn?.addEventListener("click", liveCheck);
  bindCheckboxes();
  liveCheck();
})();
