(() => {
  // Use the hosted API for OAuth so callback, status and disconnect all use
  // the same account data.
  const api = localStorage.getItem("highCustomIntegrationApiBase") || "https://high-custom-app.onrender.com/api";
  const token = localStorage.getItem("highCustomAdminToken");
  const request = async (path, options = {}) => {
    const response = await fetch(api + path, { ...options, headers: { Authorization: `Bearer ${token}`, Accept: "application/json", ...(options.headers || {}) } });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok || payload.success === false) throw new Error(payload.message || "Unable to complete this request.");
    return payload;
  };
  const date = (value) => value ? new Intl.DateTimeFormat("en-IN", { dateStyle: "medium", timeStyle: "short" }).format(new Date(value)) : "—";
  const showOAuthResult = () => {
    const params = new URLSearchParams(location.search);
    const provider = params.get("provider");
    if (!provider || !params.has("success")) return;
    const success = params.get("success") === "true";
    const label = provider === "zoho" ? "Zoho" : "Gmail";
    alert(success ? `${label} connected${params.get("email") ? `: ${params.get("email")}` : " successfully."}` : `${label} connection failed: ${params.get("error") || "Please try again."}`);
    history.replaceState({}, document.title, location.pathname);
  };
  const paint = (provider, data) => {
    const status = document.getElementById(`${provider}Status`), action = document.getElementById(`${provider}Action`), meta = document.getElementById(`${provider}Meta`);
    // Older deployed backends report a saved Zoho account with a missing
    // optional capability as reconnectRequired. It is still connected and
    // must not be presented as a disconnected account.
    const reconnectNeeded = Boolean(data?.sendPermissionMissing || data?.reconnectRequired);
    const connected = Boolean(data?.connected || (data?.reconnectRequired && data?.email));
    status.textContent = connected ? "● Connected" : "● Not Connected"; status.className = `status ${connected ? "connected" : "offline"}`;
    action.textContent = connected ? (reconnectNeeded ? "Reconnect" : "Disconnect") : "Connect"; action.className = `action ${connected && !reconnectNeeded ? "danger" : "primary"}`;
    meta.hidden = !connected;
    if (connected) meta.innerHTML = `<div><strong>${data.email || "Connected account"}</strong>Connected Email</div><div><strong>${date(data.connectedAt)}</strong>Connected On</div><div><strong>${reconnectNeeded ? "Reconnect needed" : data.syncHealthy === false ? "Needs attention" : "Active"}</strong>Status</div>`;
    action.onclick = async () => { try { action.disabled = true; if (connected && !reconnectNeeded) { await request(`/integrations/${provider}/disconnect`, { method: "DELETE" }); await load(provider); } else { const returnUrl = new URL("integrations.html", location.href).href; const result = await request(`/integrations/${provider}/connect?returnUrl=${encodeURIComponent(returnUrl)}`); if (result.authUrl) location.assign(result.authUrl); } } catch (error) { alert(error.message); } finally { action.disabled = false; } };
  };
  const load = async (provider) => { try { const result = await request(`/integrations/${provider}/status`); paint(provider, result.data || result); } catch (error) { paint(provider, { connected: false }); } };
  if (!token) location.replace("admin-login.html"); else { showOAuthResult(); ["gmail", "zoho"].forEach(load); }
})();
