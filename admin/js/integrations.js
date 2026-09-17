(() => {
  "use strict";

  const isLocal = ["localhost", "127.0.0.1"].includes(location.hostname);
  const api = isLocal
    ? "http://localhost:3000/api"
    : localStorage.getItem("highCustomIntegrationApiBase") ||
      localStorage.getItem("highCustomApiBase") ||
      "https://high-custom-app.onrender.com/api";
  const token = localStorage.getItem("highCustomAdminToken");
  const providers = ["gmail", "zoho", "godaddy"];
  const goDaddyModalElement = document.getElementById("godaddyModal");
  const goDaddyModal =
    goDaddyModalElement && window.bootstrap
      ? new bootstrap.Modal(goDaddyModalElement)
      : null;

  const request = async (path, options = {}) => {
    const response = await fetch(api + path, {
      ...options,
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/json",
        ...(options.body ? { "Content-Type": "application/json" } : {}),
        ...(options.headers || {}),
      },
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok || payload.success === false) {
      throw new Error(payload.message || "Unable to complete this request.");
    }
    return payload;
  };

  const formatDate = (value) =>
    value
      ? new Intl.DateTimeFormat("en-IN", {
          dateStyle: "medium",
          timeStyle: "short",
        }).format(new Date(value))
      : "—";

  const message = (text, isError = false) => {
    const existing = document.querySelector(".integration-toast");
    existing?.remove();
    const toast = document.createElement("div");
    toast.className = "integration-toast";
    toast.textContent = text;
    Object.assign(toast.style, {
      position: "fixed", top: "96px", right: "24px", zIndex: "3000",
      padding: "12px 16px", borderRadius: "10px", color: "#fff",
      background: isError ? "#c43145" : "#087b43", fontWeight: "700",
      boxShadow: "0 12px 26px rgba(15,23,68,.2)",
    });
    document.body.append(toast);
    setTimeout(() => toast.remove(), 3200);
  };

  const providerLabel = (provider) =>
    ({ gmail: "Gmail", zoho: "Zoho", godaddy: "GoDaddy Email" })[provider] || provider;

  const paint = (provider, data = {}) => {
    const status = document.getElementById(`${provider}Status`);
    const action = document.getElementById(`${provider}Action`);
    const meta = document.getElementById(`${provider}Meta`);
    if (!status || !action || !meta) return;

    const reconnectNeeded = Boolean(data.sendPermissionMissing || data.reconnectRequired);
    const connected = Boolean(data.connected || (data.reconnectRequired && data.email));
    status.textContent = connected ? "Connected" : "Not Connected";
    status.className = `status ${connected ? "connected" : "offline"}`;
    action.textContent = connected ? (reconnectNeeded ? "Reconnect" : "Disconnect") : "Connect";
    action.className = `action ${connected && !reconnectNeeded ? "danger" : "primary"}`;
    meta.hidden = !connected;
    if (connected) {
      meta.innerHTML = `<strong>${escapeHtml(data.email || "Connected account")}</strong> Connected on ${escapeHtml(formatDate(data.connectedAt))}`;
    }
    action.onclick = () => handleAction(provider, connected, reconnectNeeded, action);
  };

  const escapeHtml = (value) => String(value ?? "").replace(/[&<>"']/g, (character) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;",
  })[character]);

  async function handleAction(provider, connected, reconnectNeeded, action) {
    if (provider === "godaddy" && (!connected || reconnectNeeded)) {
      document.getElementById("godaddyError").hidden = true;
      document.getElementById("godaddyPassword").value = "";
      goDaddyModal?.show();
      return;
    }
    try {
      action.disabled = true;
      if (connected && !reconnectNeeded) {
        await request(`/integrations/${provider}/disconnect`, { method: "DELETE" });
        message(`${providerLabel(provider)} disconnected.`);
        await load(provider);
        return;
      }
      const returnUrl = new URL("integrations.html", location.href).href;
      const result = await request(
        `/integrations/${provider}/connect?returnUrl=${encodeURIComponent(returnUrl)}`,
      );
      if (result.authUrl) location.assign(result.authUrl);
    } catch (error) {
      message(error.message, true);
    } finally {
      action.disabled = false;
    }
  }

  async function load(provider) {
    try {
      const result = await request(`/integrations/${provider}/status`);
      paint(provider, result.data || result);
    } catch (error) {
      paint(provider, { connected: false });
    }
  }

  function showOAuthResult() {
    const params = new URLSearchParams(location.search);
    const provider = params.get("provider");
    if (!provider || !params.has("success")) return;
    const succeeded = params.get("success") === "true";
    message(
      succeeded
        ? `${providerLabel(provider)} connected${params.get("email") ? `: ${params.get("email")}` : " successfully."}`
        : `${providerLabel(provider)} connection failed: ${params.get("error") || "Please try again."}`,
      !succeeded,
    );
    history.replaceState({}, document.title, location.pathname);
  }

  function setupGoDaddyForm() {
    const form = document.getElementById("godaddyForm");
    if (!form) return;
    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      const submit = document.getElementById("godaddySubmit");
      const error = document.getElementById("godaddyError");
      error.hidden = true;
      try {
        submit.disabled = true;
        submit.textContent = "Verifying…";
        const values = Object.fromEntries(new FormData(form));
        await request("/integrations/godaddy/connect", {
          method: "POST", body: JSON.stringify(values),
        });
        goDaddyModal?.hide();
        // Use a real page navigation after a successful SMTP verification.
        // This guarantees the integration page reloads its newly saved status.
        location.assign(`${location.pathname}?provider=godaddy&success=true`);
      } catch (requestError) {
        error.textContent = requestError.message;
        error.hidden = false;
      } finally {
        submit.disabled = false;
        submit.textContent = "Verify & Connect";
      }
    });
  }

  function setupFilters() {
    const search = document.getElementById("integrationSearch");
    const category = document.getElementById("integrationCategory");
    const filter = () => {
      const phrase = String(search?.value || "").trim().toLowerCase();
      const selected = category?.value || "all";
      document.querySelectorAll(".integration-card").forEach((card) => {
        const match = (!phrase || card.textContent.toLowerCase().includes(phrase)) &&
          (selected === "all" || card.dataset.category === selected);
        card.hidden = !match;
      });
    };
    search?.addEventListener("input", filter);
    category?.addEventListener("change", filter);
  }

  if (!token) {
    location.replace("admin-login.html");
    return;
  }
  showOAuthResult();
  setupGoDaddyForm();
  setupFilters();
  providers.forEach(load);
})();
