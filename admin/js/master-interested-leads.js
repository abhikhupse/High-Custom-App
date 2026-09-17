(() => {
  "use strict";
  if (new URLSearchParams(location.search).get("status") !== "interested")
    return;

  const token = localStorage.getItem("highCustomAdminToken");
  if (!token) return;
  const api = ["localhost", "127.0.0.1"].includes(location.hostname)
    ? "http://localhost:3000/api"
    : localStorage.getItem("highCustomApiBase") ||
      "https://high-custom-app.onrender.com/api";
  const state = { page: 1, limit: 10, rows: [], typesLoaded: false };
  const esc = (v) =>
    String(v ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  const owner = () => {
    try {
      const user = JSON.parse(
        localStorage.getItem("highCustomAdminUser") || "{}",
      );
      return (
        [user.firstName, user.lastName].filter(Boolean).join(" ") ||
        user.name ||
        user.email ||
        "Current Admin"
      );
    } catch (_) {
      return "Current Admin";
    }
  };
  const initials = (v) =>
    String(v)
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 2)
      .map((x) => x[0])
      .join("")
      .toUpperCase() || "A";
  const when = (v) =>
    v
      ? new Date(v).toLocaleString("en-GB", {
          day: "numeric",
          month: "short",
          year: "numeric",
          hour: "2-digit",
          minute: "2-digit",
        })
      : "—";
  const dateRange = (v) => {
    if (!v) return {};
    const end = new Date(),
      start = new Date();
    if (v === "today") start.setHours(0, 0, 0, 0);
    if (v === "7days") start.setDate(end.getDate() - 6);
    if (v === "30days") start.setDate(end.getDate() - 29);
    return {
      startDate: start.toISOString().slice(0, 10),
      endDate: end.toISOString().slice(0, 10),
    };
  };
  const call = async (path, options = {}) => {
    const res = await fetch(api + path, {
      ...options,
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token}`,
        ...(options.headers || {}),
      },
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok || data.success === false)
      throw new Error(data.message || "Unable to load interested leads.");
    return data;
  };
  const shell =
    () => `<section id="adminLeadsPage" class="interested-leads-page">
    <div class="leads-header"><h1 class="main-title">Interested Leads</h1><p class="sub-title">View and manage interested leads for your workspace.</p></div>
    <div class="filter-bar" aria-label="Interested lead filters">
      <div class="filter-group"><label for="masterInterestSearch">Search</label><input id="masterInterestSearch" class="form-control" type="search" placeholder="Search by email, name, company..."></div>
      <div class="filter-group"><label for="masterInterestOwner">User</label><select id="masterInterestOwner" class="form-select" disabled><option>${esc(owner())}</option></select></div>
      <div class="filter-group"><label for="masterInterestType">Business Type</label><select id="masterInterestType" class="form-select"><option value="">All Business Types</option></select></div>
      <div class="filter-group"><label for="masterInterestDate">Date Range</label><select id="masterInterestDate" class="form-select"><option value="">Date Range</option><option value="today">Today</option><option value="7days">Last 7 Days</option><option value="30days">Last 30 Days</option></select></div>
      <div class="filter-buttons"><button id="masterInterestReset" class="btn" type="button"><i class="fas fa-rotate-right me-2"></i>Reset</button></div>
    </div>
    <div class="leads-card"><div class="table-responsive"><table class="table leads-table w-100"><thead><tr><th>#</th><th>Name</th><th>Contact Details</th><th>Company</th><th>Location</th><th>Related Sequence</th><th>Submitted By</th><th>Date</th><th>Actions</th></tr></thead><tbody id="masterInterestRows"></tbody></table></div><div class="leads-pagination" id="masterInterestPages"></div></div>
  </section>`;
  const render = (pagination = {}) => {
    const body = document.getElementById("masterInterestRows");
    const first = (state.page - 1) * state.limit;
    body.innerHTML = state.rows.length
      ? state.rows
          .map((item, i) => {
            const phone = item.mobileNumber || "",
              email = item.leadId?.email || "";
            const wa = phone
              ? `https://wa.me/${String(phone).replace(/\D/g, "")}`
              : "";
            const location =
              [item.city, item.state, item.country]
                .filter(Boolean)
                .join(", ") || "—";
            const currentOwner = owner();
            return `<tr><td class="lead-row-no">${first + i + 1}</td><td class="interested-name">${esc(item.name || "—")}</td><td><span class="interested-contact">${phone ? `<span><i class="fas fa-phone"></i>${esc(phone)}</span>` : ""}${email ? `<span><i class="far fa-envelope"></i>${esc(email)}</span>` : "—"}</span></td><td>${esc(item.companyName || item.leadId?.company || "—")}</td><td><span class="interested-location"><i class="fas fa-location-dot"></i>${esc(location)}</span></td><td class="interested-sequence" title="${esc(item.sequenceId?.subject || "")}">${esc(item.sequenceId?.subject || "—")}</td><td><span class="lead-owner"><span class="lead-owner-avatar owner-blue">${esc(initials(currentOwner))}</span><span>${esc(currentOwner)}<small>Your workspace</small></span></span></td><td>${esc(when(item.submittedAt))}</td><td><span class="interested-actions">${phone ? `<a href="tel:${esc(phone)}" title="Call"><i class="fas fa-phone"></i></a>` : ""}${wa ? `<a class="whatsapp" href="${esc(wa)}" target="_blank" rel="noopener" title="WhatsApp"><i class="fab fa-whatsapp"></i></a>` : ""}<button type="button" class="delete-interest" data-interest-delete="${esc(item._id)}" title="Delete interested response"><i class="far fa-trash-can"></i></button></span></td></tr>`;
          })
          .join("")
      : '<tr><td colspan="9" class="text-center py-5 text-muted">No interested leads found.</td></tr>';
    const total = Number(pagination.total || 0),
      pages = Math.max(Number(pagination.totalPages || 1), 1);
    const buttons = Array.from(
      { length: Math.min(pages, 5) },
      (_, i) =>
        `<button type="button" data-page="${i + 1}" class="${state.page === i + 1 ? "active" : ""}">${i + 1}</button>`,
    ).join("");
    document.getElementById("masterInterestPages").innerHTML =
      `<span>Showing ${total ? first + 1 : 0} to ${Math.min(first + state.limit, total)} of ${total} interested leads</span><span class="lead-pages"><button type="button" data-page="${state.page - 1}" ${state.page === 1 ? "disabled" : ""}><i class="fas fa-chevron-left"></i></button>${buttons}<button type="button" data-page="${state.page + 1}" ${state.page >= pages ? "disabled" : ""}><i class="fas fa-chevron-right"></i></button><span class="master-page-picker"><button type="button" class="master-page-picker-trigger" aria-expanded="false">${state.limit} <span>/ page</span><i class="fas fa-chevron-down"></i></button><span class="master-page-picker-menu">${[10, 20, 50, 100].map((size) => `<button type="button" data-master-page-size="${size}" class="${state.limit === size ? "selected" : ""}">${size} <span>/ page</span>${state.limit === size ? '<i class="fas fa-check"></i>' : ""}</button>`).join("")}</span></span></span>`;
  };
  const load = async () => {
    const query = new URLSearchParams({ page: state.page, limit: state.limit });
    const search = document
      .getElementById("masterInterestSearch")
      ?.value.trim();
    const type = document.getElementById("masterInterestType")?.value;
    if (search) query.set("search", search);
    if (type) query.set("businessType", type);
    Object.entries(
      dateRange(document.getElementById("masterInterestDate")?.value),
    ).forEach(([k, v]) => query.set(k, v));
    const data = await call(`/leads/interested-leads?${query}`);
    state.rows = data.details || [];
    if (!state.typesLoaded) {
      state.typesLoaded = true;
      document
        .getElementById("masterInterestType")
        .insertAdjacentHTML(
          "beforeend",
          (data.filterOptions?.businessTypes || [])
            .map((type) => `<option value="${esc(type)}">${esc(type)}</option>`)
            .join(""),
        );
    }
    render(data.pagination);
  };
  const showError = (error) => {
    const body = document.getElementById("masterInterestRows");
    if (body)
      body.innerHTML = `<tr><td colspan="9" class="text-center py-5 text-danger">${esc(error.message)}</td></tr>`;
  };
  document.addEventListener("DOMContentLoaded", () =>
    setTimeout(async () => {
      const main = document.getElementById("mainContent");
      if (!main) return;
      main.innerHTML = shell();
      let timer;
      main.addEventListener("input", (event) => {
        if (event.target.id === "masterInterestSearch") {
          clearTimeout(timer);
          timer = setTimeout(() => {
            state.page = 1;
            load().catch(showError);
          }, 250);
        }
      });
      main.addEventListener("change", (event) => {
        if (
          ["masterInterestType", "masterInterestDate"].includes(event.target.id)
        ) {
          state.page = 1;
          load().catch(showError);
        }
      });
      main.addEventListener("click", async (event) => {
        const pager = event.target.closest("[data-page]");
        if (pager && !pager.disabled) {
          state.page = Number(pager.dataset.page);
          return load().catch(showError);
        }
        const picker = event.target.closest(".master-page-picker-trigger");
        if (picker) {
          const wrap = picker.closest(".master-page-picker");
          const open = !wrap.classList.contains("open");
          document
            .querySelectorAll(".master-page-picker.open")
            .forEach((item) => item.classList.remove("open"));
          wrap.classList.toggle("open", open);
          picker.setAttribute("aria-expanded", String(open));
          return;
        }
        const pageSize = event.target.closest("[data-master-page-size]");
        if (pageSize) {
          state.limit = Number(pageSize.dataset.masterPageSize);
          state.page = 1;
          return load().catch(showError);
        }
        if (event.target.closest("#masterInterestReset")) {
          [
            "masterInterestSearch",
            "masterInterestType",
            "masterInterestDate",
          ].forEach((id) => {
            document.getElementById(id).value = "";
          });
          state.page = 1;
          return load().catch(showError);
        }
        const remove = event.target.closest("[data-interest-delete]");
        if (
          !remove ||
          !confirm(
            "Remove this interested response? The original lead will remain.",
          )
        )
          return;
        try {
          await call(
            `/leads/interested-leads/${encodeURIComponent(remove.dataset.interestDelete)}`,
            { method: "DELETE" },
          );
          window.toastr?.success("Interested lead record deleted.");
          await load();
        } catch (error) {
          window.toastr?.error(error.message);
        }
      });
      document.addEventListener("click", (event) => {
        if (!event.target.closest(".master-page-picker"))
          document
            .querySelectorAll(".master-page-picker.open")
            .forEach((item) => item.classList.remove("open"));
      });
      await load().catch(showError);
    }, 70),
  );
})();
