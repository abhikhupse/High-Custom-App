(function () {
  "use strict";
  const table = document.getElementById("UserSequenceTable");
  if (!table) return;

  const token = localStorage.getItem("highCustomAdminToken");
  const local = ["localhost", "127.0.0.1"].includes(location.hostname);
  const apiBase = local ? "http://localhost:3000/api" : (localStorage.getItem("highCustomApiBase") || "https://high-custom-app.onrender.com/api");
  const state = { page: 1, limit: 10, rows: [] };
  const esc = (value) => String(value ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/\"/g, "&quot;");
  const request = async (path) => {
    const response = await fetch(apiBase + path, { headers: { Accept: "application/json", Authorization: `Bearer ${token}` } });
    const data = await response.json().catch(() => ({}));
    if (!response.ok || data.success === false) throw new Error(data.message || "Unable to load tracking data.");
    return data;
  };
  const range = (value) => {
    if (!value) return {};
    const end = new Date(); const start = new Date();
    if (value === "today") start.setHours(0, 0, 0, 0);
    if (value === "7days") start.setDate(end.getDate() - 6);
    if (value === "30days") start.setDate(end.getDate() - 29);
    return { startDate: start.toISOString().slice(0, 10), endDate: end.toISOString().slice(0, 10) };
  };
  const date = (value) => value ? new Date(value).toLocaleString("en-GB", { day: "numeric", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" }) : "—";
  const initials = (value) => String(value || "—").split(/\s+/).filter(Boolean).slice(0, 2).map((part) => part[0]).join("").toUpperCase();
  const tone = (value) => ["gold", "blue", ""][String(value || "").length % 3];
  const status = (value) => {
    const raw = String(value || "Pending");
    const normalized = raw.replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase().replace(/\s+/g, "-");
    const supported = ["sent", "pending", "failed", "opened", "interested", "not-interested"];
    return `<span class="tracking-status-pill ${supported.includes(normalized) ? normalized : "pending"}">${esc(normalized === "not-interested" ? "Not Interested" : raw)}</span>`;
  };
  const click = (icon, name, count) => `<span class="tracking-click ${name}"><i class="${icon}"></i>${Number(count || 0)}</span>`;

  function pagination(meta) {
    const host = document.getElementById("adminTrackingPagination");
    if (!host) return;
    const total = Number(meta.total || 0); const pages = Math.max(Number(meta.totalPages || 1), 1); const page = Number(meta.page || state.page);
    state.page = page;
    const first = Math.max(1, Math.min(page - 2, Math.max(pages - 4, 1)));
    const pagesHtml = Array.from({ length: Math.min(pages - first + 1, 5) }, (_, index) => {
      const number = first + index;
      return `<button type="button" class="${number === page ? "active" : ""}" data-tracking-page="${number}">${number}</button>`;
    }).join("");
    host.innerHTML = `<span>Showing ${total ? (page - 1) * state.limit + 1 : 0} to ${Math.min(page * state.limit, total)} of ${total} records</span><span class="tracking-pages"><button type="button" data-tracking-page="${page - 1}" ${page <= 1 ? "disabled" : ""}><i class="fas fa-chevron-left"></i></button>${pagesHtml}<button type="button" data-tracking-page="${page + 1}" ${page >= pages ? "disabled" : ""}><i class="fas fa-chevron-right"></i></button><select class="tracking-page-size" id="adminTrackingBottomPageSize"><option value="10" ${state.limit === 10 ? "selected" : ""}>10 / page</option><option value="25" ${state.limit === 25 ? "selected" : ""}>25 / page</option><option value="50" ${state.limit === 50 ? "selected" : ""}>50 / page</option></select></span>`;
  }

  async function render() {
    const search = document.getElementById("adminTrackingSearch")?.value.trim() || "";
    const userId = document.getElementById("adminTrackingUser")?.value || "";
    const businessType = document.getElementById("adminTrackingBusinessType")?.value || "";
    const step = document.getElementById("adminTrackingStep")?.value || "";
    const statusValue = document.getElementById("adminTrackingStatus")?.value || "";
    const query = new URLSearchParams({ page: String(state.page), limit: String(state.limit) });
    if (search) query.set("search", search); if (userId) query.set("userId", userId); if (businessType) query.set("businessType", businessType); if (step) query.set("step", step); if (statusValue) query.set("status", statusValue);
    Object.entries(range(document.getElementById("adminTrackingDateRange")?.value || "")).forEach(([key, value]) => query.set(key, value));
    try {
      const data = await request(`/admin/tracking-report?${query}`);
      const rows = data.data || []; state.rows = rows;
      const businessSelect = document.getElementById("adminTrackingBusinessType");
      if (businessSelect && !businessSelect.dataset.loaded) { businessSelect.insertAdjacentHTML("beforeend", (data.filterOptions?.businessTypes || []).map((item) => `<option value="${esc(item)}">${esc(item)}</option>`).join("")); businessSelect.dataset.loaded = "true"; }
      const stepSelect = document.getElementById("adminTrackingStep");
      if (stepSelect && !stepSelect.dataset.loaded) { stepSelect.insertAdjacentHTML("beforeend", (data.filterOptions?.steps || []).map((item) => `<option value="${esc(item)}">Step ${esc(item)}</option>`).join("")); stepSelect.dataset.loaded = "true"; }
      const body = table.tBodies[0] || table.appendChild(document.createElement("tbody"));
      body.innerHTML = rows.length ? rows.map((item, index) => {
        const owner = item.full_name || "—";
        return `<tr><td>${(state.page - 1) * state.limit + index + 1}</td><td><span class="tracking-owner"><span class="tracking-owner-avatar ${tone(owner)}">${esc(initials(item.lead_name))}</span>${esc(item.lead_name || "—")}</span></td><td>${esc(item.lead_email || "—")}</td><td><span class="tracking-business">${esc(item.business_type || "—")}</span></td><td><span class="tracking-step">${esc(item.step || "—")}</span></td><td title="${esc(item.subject)}">${esc(item.subject || "—")}</td><td>${esc(date(item.scheduled_at))}</td><td>${status(item.status_badge)}</td><td>${esc(date(item.sent_at))}</td><td>${esc(date(item.seen_at))}</td><td>${click("fab fa-whatsapp", "whatsapp", item.whatsapp_clicks)}</td><td>${click("fab fa-instagram", "instagram", item.instagram_clicks)}</td><td>${click("fab fa-facebook-messenger", "messenger", item.facebook_messenger_clicks)}</td><td>${esc(Number(item.threads_clicks || 0))}</td><td><button type="button" class="tracking-action" data-tracking-view="${index}" title="View details"><i class="fas fa-eye"></i></button></td></tr>`;
      }).join("") : '<tr><td colspan="15" class="text-center py-5 text-muted">No tracking data available.</td></tr>';
      pagination(data.pagination || {});
    } catch (error) {
      const body = table.tBodies[0] || table.appendChild(document.createElement("tbody"));
      body.innerHTML = `<tr><td colspan="15" class="text-center py-5 text-danger">${esc(error.message)}</td></tr>`;
    }
  }

  async function setup() {
    const today = document.getElementById("adminTrackingToday");
    if (today) today.textContent = new Date().toLocaleString("en-GB", { day: "numeric", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" });
    try {
      const users = (await request("/admin/users")).data || [];
      const userSelect = document.getElementById("adminTrackingUser");
      if (userSelect) userSelect.insertAdjacentHTML("beforeend", users.map((user) => { const name = `${user.firstName || ""} ${user.lastName || ""}`.trim() || user.email; return `<option value="${esc(user._id)}">${esc(name)}</option>`; }).join(""));
    } catch (_) { /* Main table still reports its own data error if access is unavailable. */ }
    let timer;
    document.getElementById("adminTrackingSearch")?.addEventListener("input", () => { clearTimeout(timer); timer = setTimeout(() => { state.page = 1; render(); }, 300); });
    ["adminTrackingUser", "adminTrackingBusinessType", "adminTrackingStep", "adminTrackingStatus", "adminTrackingDateRange"].forEach((id) => document.getElementById(id)?.addEventListener("change", () => { state.page = 1; render(); }));
    document.getElementById("adminTrackingPageSize")?.addEventListener("change", (event) => { state.limit = Number(event.target.value); state.page = 1; render(); });
    document.getElementById("adminTrackingRefresh")?.addEventListener("click", render);
    document.getElementById("adminTrackingPagination")?.addEventListener("click", (event) => { const button = event.target.closest("[data-tracking-page]"); if (!button || button.disabled) return; state.page = Number(button.dataset.trackingPage); render(); });
    document.getElementById("adminTrackingPagination")?.addEventListener("change", (event) => { if (event.target.id !== "adminTrackingBottomPageSize") return; state.limit = Number(event.target.value); document.getElementById("adminTrackingPageSize").value = String(state.limit); state.page = 1; render(); });
    table.addEventListener("click", (event) => { const button = event.target.closest("[data-tracking-view]"); if (!button) return; const item = state.rows[Number(button.dataset.trackingView)]; if (!item) return; const detail = `Lead: ${item.lead_name || "—"}\nEmail: ${item.lead_email || "—"}\nSubject: ${item.subject || "—"}\nStatus: ${item.status_badge || "—"}\nOwner: ${item.full_name || "—"}`; window.Swal ? Swal.fire({ title: "Tracking details", text: detail, icon: "info" }) : window.alert(detail); });
    const exportRows = () => state.rows.map((item) => ({ "Lead Name": item.lead_name, "Lead Email": item.lead_email, "Business Type": item.business_type, Step: item.step, Subject: item.subject, Status: item.status_badge, "Scheduled At": date(item.scheduled_at), "Sent At": date(item.sent_at), "Seen At": date(item.seen_at), Owner: item.full_name }));
    const download = (extension, separator) => { const rows = exportRows(); const headers = Object.keys(rows[0] || {}); const encode = (value) => `"${String(value ?? "").replace(/"/g, '""')}"`; const content = [headers.join(separator), ...rows.map((row) => headers.map((header) => encode(row[header])).join(separator))].join("\n"); const blob = new Blob([content], { type: extension === "csv" ? "text/csv;charset=utf-8" : "application/vnd.ms-excel" }); const link = document.createElement("a"); link.href = URL.createObjectURL(blob); link.download = `all-tracking-report.${extension}`; link.click(); URL.revokeObjectURL(link.href); };
    document.getElementById("adminTrackingExportCsv")?.addEventListener("click", () => download("csv", ","));
    document.getElementById("adminTrackingExportExcel")?.addEventListener("click", () => download("xls", "\t"));
    render();
  }
  setup();
})();
