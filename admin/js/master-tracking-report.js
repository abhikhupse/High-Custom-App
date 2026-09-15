(() => {
  "use strict";
  const table = document.getElementById("masterTrackingTable");
  if (!table) return;

  const token = localStorage.getItem("highCustomAdminToken");
  const local = ["localhost", "127.0.0.1"].includes(location.hostname);
  const apiBase = local
    ? "http://localhost:3000/api"
    : localStorage.getItem("highCustomApiBase") ||
      "https://high-custom-app.onrender.com/api";
  const state = { page: 1, limit: 10, rows: [] };
  const esc = (value) =>
    String(value ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  const date = (value) =>
    value
      ? new Date(value).toLocaleString("en-GB", {
          day: "numeric",
          month: "short",
          year: "numeric",
          hour: "2-digit",
          minute: "2-digit",
        })
      : "—";
  const name = (item) =>
    `${item.leadId?.firstName || ""} ${item.leadId?.lastName || ""}`.trim() ||
    item.leadId?.name ||
    "—";
  const initials = (value) =>
    String(value || "—")
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part[0])
      .join("")
      .toUpperCase();
  const normalizedStatus = (item) =>
    item.responseStatus ||
    (item.repliedAt
      ? "Replied"
      : item.openedAt
        ? "Opened"
        : item.status || "Pending");
  const status = (item) => {
    const raw = normalizedStatus(item);
    const key = raw.toLowerCase().replace(/\s+/g, "-");
    return `<span class="tracking-status-pill ${["sent", "pending", "failed", "opened", "interested", "not-interested"].includes(key) ? key : "pending"}">${esc(raw)}</span>`;
  };
  const click = (icon, kind, value) =>
    `<span class="tracking-click ${kind}"><i class="${icon}"></i>${Number(value || 0)}</span>`;
  const actionLinks = (links) =>
    Array.isArray(links) && links.length
      ? links
          .map(
            (link) =>
              `<div class="tracking-action-link"><strong>${esc(link.label || link.type || "Action Link")}</strong> <span>${esc(link.status || "Not Clicked")} · ${Number(link.clickCount || 0)} ${Number(link.clickCount || 0) === 1 ? "click" : "clicks"}</span>${link.lastClickedAt ? `<small>${esc(date(link.lastClickedAt))}</small>` : ""}</div>`,
          )
          .join("")
      : '<span class="text-muted">—</span>';
  const range = (value) => {
    if (!value) return {};
    const end = new Date();
    const start = new Date();
    if (value === "today") start.setHours(0, 0, 0, 0);
    if (value === "7days") start.setDate(end.getDate() - 6);
    if (value === "30days") start.setDate(end.getDate() - 29);
    return {
      startDate: start.toISOString().slice(0, 10),
      endDate: end.toISOString().slice(0, 10),
    };
  };
  const request = async (path) => {
    const response = await fetch(apiBase + path, {
      headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok || data.success === false)
      throw new Error(data.message || "Unable to load tracking data.");
    return data;
  };

  const headerRow = table.tHead?.rows[0];
  const seenHeader =
    headerRow &&
    [...headerRow.cells].find((cell) => cell.textContent.trim() === "Seen At");
  if (
    seenHeader &&
    ![...headerRow.cells].some(
      (cell) => cell.textContent.trim() === "Action Links",
    )
  ) {
    seenHeader.insertAdjacentHTML("afterend", "<th>Action Links</th>");
  }

  function pagination(meta) {
    const host = document.getElementById("masterTrackingPagination");
    if (!host) return;
    const total = Number(meta.total || 0),
      pages = Math.max(Number(meta.totalPages || 1), 1),
      page = Number(meta.page || state.page);
    state.page = page;
    const first = Math.max(1, Math.min(page - 2, Math.max(pages - 4, 1)));
    const buttons = Array.from(
      { length: Math.min(pages - first + 1, 5) },
      (_, index) => {
        const value = first + index;
        return `<button type="button" class="${value === page ? "active" : ""}" data-master-page="${value}">${value}</button>`;
      },
    ).join("");
    host.innerHTML = `<span>Showing ${total ? (page - 1) * state.limit + 1 : 0} to ${Math.min(page * state.limit, total)} of ${total} records</span><span class="tracking-pages"><button type="button" data-master-page="${page - 1}" ${page <= 1 ? "disabled" : ""}><i class="fas fa-chevron-left"></i></button>${buttons}<button type="button" data-master-page="${page + 1}" ${page >= pages ? "disabled" : ""}><i class="fas fa-chevron-right"></i></button><select class="tracking-page-size" id="masterTrackingBottomSize"><option value="10" ${state.limit === 10 ? "selected" : ""}>10 / page</option><option value="25" ${state.limit === 25 ? "selected" : ""}>25 / page</option><option value="50" ${state.limit === 50 ? "selected" : ""}>50 / page</option></select></span>`;
  }

  async function render() {
    const query = new URLSearchParams({
      page: String(state.page),
      limit: String(state.limit),
    });
    const search = document
      .getElementById("masterTrackingSearch")
      ?.value.trim();
    const statusValue = document.getElementById("masterTrackingStatus")?.value;
    if (search) query.set("search", search);
    if (statusValue) query.set("status", statusValue);
    Object.entries(
      range(document.getElementById("masterTrackingDateRange")?.value || ""),
    ).forEach(([key, value]) => query.set(key, value));
    try {
      const data = await request(`/email-tracking/report?${query}`);
      let rows = data.deliveries || [];
      const selectedStep =
        document.getElementById("masterTrackingStep")?.value || "";
      const selectedType =
        document.getElementById("masterTrackingBusinessType")?.value || "";
      if (selectedStep)
        rows = rows.filter(
          (item) => String(item.sequenceId?.step || "") === selectedStep,
        );
      if (selectedType)
        rows = rows.filter(
          (item) => String(item.sequenceId?.type || "") === selectedType,
        );
      state.rows = rows;
      ["masterTrackingStep", "masterTrackingBusinessType"].forEach((id) => {
        const select = document.getElementById(id);
        if (!select || select.dataset.loaded) return;
        const key = id.includes("Step") ? "step" : "type";
        const values = [
          ...new Set(
            (data.deliveries || [])
              .map((item) => item.sequenceId?.[key])
              .filter(Boolean),
          ),
        ];
        select.insertAdjacentHTML(
          "beforeend",
          values
            .map(
              (value) =>
                `<option value="${esc(value)}">${key === "step" ? `Step ${esc(value)}` : esc(value)}</option>`,
            )
            .join(""),
        );
        select.dataset.loaded = "true";
      });
      const body = table.tBodies[0];
      body.innerHTML = rows.length
        ? rows
            .map(
              (item, index) =>
                `<tr><td>${(state.page - 1) * state.limit + index + 1}</td><td><span class="tracking-owner"><span class="tracking-owner-avatar">${esc(initials(name(item)))}</span>${esc(name(item))}</span></td><td>${esc(item.leadId?.email || item.email || "—")}</td><td><span class="tracking-business">${esc(item.sequenceId?.type || "—")}</span></td><td><span class="tracking-step">${esc(item.sequenceId?.step || "—")}</span></td><td title="${esc(item.sequenceId?.subject || "")}">${esc(item.sequenceId?.subject || "—")}</td><td>${esc(date(item.createdAt))}</td><td>${status(item)}</td><td>${esc(date(item.sentAt))}</td><td>${esc(date(item.openedAt))}</td><td>${actionLinks(item.actionLinks)}</td><td>${click("fab fa-whatsapp", "whatsapp", item.whatsapp_clicks)}</td><td>${click("fab fa-instagram", "instagram", item.instagram_clicks)}</td><td>${click("fab fa-facebook-messenger", "messenger", item.facebook_messenger_clicks)}</td><td>${esc(Number(item.threads_clicks || 0))}</td><td><button type="button" class="tracking-action" data-master-view="${index}" title="View details"><i class="fas fa-eye"></i></button></td></tr>`,
            )
            .join("")
        : '<tr><td colspan="16" class="text-center py-5 text-muted">No personal tracking data available.</td></tr>';
      pagination(data.pagination || {});
    } catch (error) {
      table.tBodies[0].innerHTML = `<tr><td colspan="16" class="text-center py-5 text-danger">${esc(error.message)}</td></tr>`;
    }
  }

  function download(extension, separator) {
    const rows = state.rows.map((item) => ({
      "Lead Name": name(item),
      "Lead Email": item.leadId?.email || item.email,
      Step: item.sequenceId?.step,
      Subject: item.sequenceId?.subject,
      Status: normalizedStatus(item),
      "Sent At": date(item.sentAt),
      "Seen At": date(item.openedAt),
    }));
    const headers = Object.keys(rows[0] || {});
    const content = [
      headers.join(separator),
      ...rows.map((row) =>
        headers
          .map((key) => `"${String(row[key] ?? "").replace(/"/g, '""')}"`)
          .join(separator),
      ),
    ].join("\n");
    const link = document.createElement("a");
    link.href = URL.createObjectURL(
      new Blob([content], {
        type: extension === "csv" ? "text/csv" : "application/vnd.ms-excel",
      }),
    );
    link.download = `my-tracking-report.${extension}`;
    link.click();
    URL.revokeObjectURL(link.href);
  }
  let timer;
  document.getElementById("masterTrackingToday").textContent = date(new Date());
  document
    .getElementById("masterTrackingSearch")
    ?.addEventListener("input", () => {
      clearTimeout(timer);
      timer = setTimeout(() => {
        state.page = 1;
        render();
      }, 300);
    });
  [
    "masterTrackingBusinessType",
    "masterTrackingStep",
    "masterTrackingStatus",
    "masterTrackingDateRange",
  ].forEach((id) =>
    document.getElementById(id)?.addEventListener("change", () => {
      state.page = 1;
      render();
    }),
  );
  document
    .getElementById("masterTrackingPageSize")
    ?.addEventListener("change", (event) => {
      state.limit = Number(event.target.value);
      state.page = 1;
      render();
    });
  document
    .getElementById("masterTrackingRefresh")
    ?.addEventListener("click", render);
  document
    .getElementById("masterTrackingPagination")
    ?.addEventListener("click", (event) => {
      const button = event.target.closest("[data-master-page]");
      if (!button || button.disabled) return;
      state.page = Number(button.dataset.masterPage);
      render();
    });
  document
    .getElementById("masterTrackingPagination")
    ?.addEventListener("change", (event) => {
      if (event.target.id !== "masterTrackingBottomSize") return;
      state.limit = Number(event.target.value);
      document.getElementById("masterTrackingPageSize").value = String(
        state.limit,
      );
      state.page = 1;
      render();
    });
  document
    .getElementById("masterTrackingExportCsv")
    ?.addEventListener("click", () => download("csv", ","));
  document
    .getElementById("masterTrackingExportExcel")
    ?.addEventListener("click", () => download("xls", "\t"));
  table.addEventListener("click", (event) => {
    const button = event.target.closest("[data-master-view]");
    if (!button) return;
    const item = state.rows[Number(button.dataset.masterView)];
    if (!item) return;
    const message = `Lead: ${name(item)}\nEmail: ${item.leadId?.email || item.email || "—"}\nSubject: ${item.sequenceId?.subject || "—"}\nStatus: ${normalizedStatus(item)}`;
    window.Swal
      ? Swal.fire({ title: "Tracking details", text: message, icon: "info" })
      : alert(message);
  });
  render();
})();
