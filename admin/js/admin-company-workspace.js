(function () {
  "use strict";
  const token = localStorage.getItem("highCustomAdminToken");
  if (!token) return;
  const local = ["localhost", "127.0.0.1"].includes(location.hostname);
  const apiBase = local
    ? "http://localhost:3000/api"
    : localStorage.getItem("highCustomApiBase") ||
      "https://high-custom-app.onrender.com/api";
  const esc = (value) =>
    String(value ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\"/g, "&quot;");
  const owner = (item) => esc(item?.owner?.name || item?.userId?.email || "—");
  const when = (value) =>
    value
      ? new Date(value).toLocaleString("en-GB", {
          dateStyle: "medium",
          timeStyle: "short",
        })
      : "—";
  const call = async (path, options = {}) => {
    const response = await fetch(apiBase + path, {
      ...options,
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token}`,
        ...(options.body ? { "Content-Type": "application/json" } : {}),
        ...(options.headers || {}),
      },
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok || data.success === false)
      throw new Error(data.message || "Unable to load company data.");
    return data;
  };
  const setEmpty = (table, columns, message) => {
    let body =
      table.tBodies[0] || table.appendChild(document.createElement("tbody"));
    body.innerHTML = `<tr><td colspan="${columns}" class="text-center py-5 text-muted">${esc(message)}</td></tr>`;
  };
  const status = (value) =>
    `<span class="badge ${
      String(value || "pending")
        .toLowerCase()
        .includes("interested")
        ? "bg-success"
        : "bg-secondary"
    }">${esc(value || "Pending")}</span>`;
  const sequenceState = { page: 1, limit: 10, rows: [], canDelete: true };
  const leadState = { page: 1, limit: 10, rows: [] };
  const initials = (value) =>
    String(value || "A")
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part[0])
      .join("")
      .toUpperCase();
  const ownerTone = (value) =>
    ["owner-gold", "owner-blue", ""].at(String(value || "").length % 3);
  const dateRange = (value) => {
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
  const sequenceStatus = (value) => {
    const name = String(value || "draft").toLowerCase();
    return `<span class="sequence-status sequence-status--${esc(name)}">${esc(name.charAt(0).toUpperCase() + name.slice(1))}</span>`;
  };
  const sequenceDate = (value) =>
    value
      ? new Date(value).toLocaleString("en-GB", {
          day: "numeric",
          month: "short",
          year: "numeric",
          hour: "2-digit",
          minute: "2-digit",
        })
      : "—";
  const leadStatus = (item) =>
    item.responseStatus === "interested"
      ? "Interested"
      : item.responseStatus === "notInterested"
        ? "Not Interested"
        : item.tracking === false
          ? "Skip"
          : "Pending";
  const leadStatusClass = (value) =>
    String(value).toLowerCase().replace(/\s+/g, "-");

  async function renderAdminLeads() {
    const table = document.getElementById("totalLeadsTable");
    if (!table) return;
    try {
      const search =
        document.getElementById("adminLeadSearch")?.value.trim() || "";
      const userId = document.getElementById("adminLeadOwner")?.value || "";
      const businessType =
        document.getElementById("adminLeadBusinessType")?.value || "";
      const isInterestedPage =
        new URLSearchParams(location.search).get("status") === "interested";
      const statusValue = isInterestedPage
        ? "interested"
        : document.getElementById("adminLeadTrackingStatus")?.value || "";
      const title = document.querySelector("#adminLeadsPage .main-title");
      const subtitle = document.querySelector("#adminLeadsPage .sub-title");
      const pageRoot = document.getElementById("adminLeadsPage");
      const trackingFilter = document
        .getElementById("adminLeadTrackingStatus")
        ?.closest(".filter-group");
      if (isInterestedPage) {
        pageRoot?.classList.add("interested-leads-page");
        if (trackingFilter) trackingFilter.hidden = true;
        if (title) title.textContent = "Interested Leads — All Users";
        if (subtitle)
          subtitle.textContent =
            "View and manage all interested leads from all users.";
      } else {
        pageRoot?.classList.remove("interested-leads-page");
        if (trackingFilter) trackingFilter.hidden = false;
      }
      const range = dateRange(
        document.getElementById("adminLeadDateRange")?.value || "",
      );
      const query = new URLSearchParams({
        limit: String(leadState.limit),
        page: String(leadState.page),
      });
      if (search) query.set("search", search);
      if (userId) query.set("userId", userId);
      if (businessType) query.set("businessType", businessType);
      if (statusValue) query.set("status", statusValue);
      Object.entries(range).forEach(([key, value]) => query.set(key, value));
      const data = await call(
        `${isInterestedPage ? "/admin/interested-leads" : "/admin/leads"}?${query}`,
      );
      const rows = isInterestedPage ? data.details || [] : data.leads || [];
      leadState.rows = rows;
      const businessSelect = document.getElementById("adminLeadBusinessType");
      if (businessSelect && !businessSelect.dataset.optionsLoaded) {
        businessSelect.insertAdjacentHTML(
          "beforeend",
          (data.filterOptions?.businessTypes || [])
            .map((type) => `<option value="${esc(type)}">${esc(type)}</option>`)
            .join(""),
        );
        businessSelect.dataset.optionsLoaded = "true";
      }
      const header = table.tHead?.rows[0];
      if (header)
        header.innerHTML = isInterestedPage
          ? "<th>#</th><th>Name</th><th>Contact Details</th><th>Company</th><th>Location</th><th>Related Sequence</th><th>Submitted By</th><th>Date</th><th>Actions</th>"
          : "<th>#</th><th>Email</th><th>Business Type</th><th>Owner</th><th>Tracking</th><th>First Name</th><th>Last Name</th><th>Company</th><th>Created At</th>";
      let body =
        table.tBodies[0] || table.appendChild(document.createElement("tbody"));
      body.innerHTML = rows.length
        ? rows
            .map((item, index) => {
              if (isInterestedPage) {
                const displayOwner =
                  item.owner?.name || item.userId?.email || "—";
                const location =
                  [item.city, item.state, item.country]
                    .filter(Boolean)
                    .join(", ") || "—";
                const mail = item.leadId?.email || "";
                const phone = item.mobileNumber || "";
                const whatsApp = phone
                  ? `https://wa.me/${String(phone).replace(/\D/g, "")}`
                  : "";
                return `<tr><td class="lead-row-no">${(leadState.page - 1) * leadState.limit + index + 1}</td><td class="interested-name">${esc(item.name || "—")}</td><td><span class="interested-contact">${phone ? `<span><i class="fas fa-phone"></i>${esc(phone)}</span>` : ""}${mail ? `<span><i class="far fa-envelope"></i>${esc(mail)}</span>` : "—"}</span></td><td>${esc(item.companyName || item.leadId?.company || "—")}</td><td><span class="interested-location"><i class="fas fa-location-dot"></i>${esc(location)}</span></td><td class="interested-sequence" title="${esc(item.sequenceId?.subject || "")}">${esc(item.sequenceId?.subject || "—")}</td><td><span class="lead-owner"><span class="lead-owner-avatar ${ownerTone(displayOwner)}">${esc(initials(displayOwner))}</span><span>${esc(displayOwner)}<small>${esc(item.owner?.email || "")}</small></span></span></td><td>${esc(sequenceDate(item.submittedAt))}</td><td><span class="interested-actions">${phone ? `<a href="tel:${esc(phone)}" title="Call"><i class="fas fa-phone"></i></a>` : ""}${whatsApp ? `<a class="whatsapp" href="${esc(whatsApp)}" target="_blank" rel="noopener" title="WhatsApp"><i class="fab fa-whatsapp"></i></a>` : ""}<button type="button" class="delete-interest" data-interest-delete="${esc(item._id)}" title="Delete interested response"><i class="far fa-trash-can"></i></button></span></td></tr>`;
              }
              const displayOwner =
                item.owner?.name || item.userId?.email || "—";
              const tracking = leadStatus(item);
              return `<tr><td class="lead-row-no">${(leadState.page - 1) * leadState.limit + index + 1}</td><td class="lead-email" title="${esc(item.email)}">${esc(item.email || "—")}</td><td><span class="lead-business-type">${esc(item.businessType || "—")}</span></td><td><span class="lead-owner"><span class="lead-owner-avatar ${ownerTone(displayOwner)}">${esc(initials(displayOwner))}</span>${esc(displayOwner)}</span></td><td><span class="lead-tracking-status lead-tracking-status--${leadStatusClass(tracking)}">${esc(tracking)}</span></td><td>${esc(item.firstName || "—")}</td><td>${esc(item.lastName || "—")}</td><td>${esc(item.company || "—")}</td><td><span class="lead-date"><i class="far fa-calendar-alt"></i>${esc(sequenceDate(item.createdAt))}</span></td></tr>`;
            })
            .join("")
        : `<tr><td colspan="${isInterestedPage ? 9 : 9}" class="text-center py-5 text-muted">No ${isInterestedPage ? "interested leads" : "leads"} found.</td></tr>`;
      renderLeadPagination(
        data.pagination || {},
        isInterestedPage ? "interested leads" : "leads",
      );
    } catch (error) {
      setEmpty(table, 10, error.message);
    }
  }

  function renderLeadPagination(pagination, noun = "leads") {
    const host = document.getElementById("adminLeadPagination");
    if (!host) return;
    const total = Number(pagination.total || 0);
    const pages = Math.max(Number(pagination.totalPages || 1), 1);
    const page = Number(pagination.page || leadState.page);
    leadState.page = page;
    const firstPage = Math.max(1, Math.min(page - 2, Math.max(pages - 4, 1)));
    const pageButtons = Array.from(
      { length: Math.min(pages - firstPage + 1, 5) },
      (_, index) => {
        const pageNumber = firstPage + index;
        return `<button type="button" class="${pageNumber === page ? "active" : ""}" data-lead-page="${pageNumber}">${pageNumber}</button>`;
      },
    ).join("");
    host.innerHTML = `<span>Showing ${total ? (page - 1) * leadState.limit + 1 : 0} to ${Math.min(page * leadState.limit, total)} of ${total} ${noun}</span><span class="lead-pages"><button type="button" data-lead-page="${page - 1}" ${page <= 1 ? "disabled" : ""}><i class="fas fa-chevron-left"></i></button>${pageButtons}<button type="button" data-lead-page="${page + 1}" ${page >= pages ? "disabled" : ""}><i class="fas fa-chevron-right"></i></button><select class="lead-page-size" id="adminLeadPageSize"><option value="10" ${leadState.limit === 10 ? "selected" : ""}>10 / page</option><option value="25" ${leadState.limit === 25 ? "selected" : ""}>25 / page</option><option value="50" ${leadState.limit === 50 ? "selected" : ""}>50 / page</option></select></span>`;
  }

  async function initialiseLeadFilters() {
    const ownerSelect = document.getElementById("adminLeadOwner");
    if (!ownerSelect || ownerSelect.dataset.backendReady === "true") return;
    ownerSelect.dataset.backendReady = "true";
    try {
      const users = (await call("/admin/users")).data || [];
      ownerSelect.insertAdjacentHTML(
        "beforeend",
        users
          .map((user) => {
            const name =
              `${user.firstName || ""} ${user.lastName || ""}`.trim() ||
              user.email;
            return `<option value="${esc(user._id)}">${esc(name)}${user.email ? ` — ${esc(user.email)}` : ""}</option>`;
          })
          .join(""),
      );
    } catch (_) {
      /* Leads remain available if optional owner options cannot load. */
    }

    let searchTimer;
    document
      .getElementById("adminLeadSearch")
      ?.addEventListener("input", () => {
        window.clearTimeout(searchTimer);
        searchTimer = window.setTimeout(() => {
          leadState.page = 1;
          renderAdminLeads();
        }, 300);
      });
    const refresh = () => {
      leadState.page = 1;
      renderAdminLeads();
    };
    ownerSelect.addEventListener("change", refresh);
    document
      .getElementById("adminLeadBusinessType")
      ?.addEventListener("change", refresh);
    document
      .getElementById("adminLeadTrackingStatus")
      ?.addEventListener("change", refresh);
    document
      .getElementById("adminLeadDateRange")
      ?.addEventListener("change", refresh);
    document.getElementById("adminLeadReset")?.addEventListener("click", () => {
      [
        "adminLeadSearch",
        "adminLeadBusinessType",
        "adminLeadTrackingStatus",
        "adminLeadDateRange",
      ].forEach((id) => {
        const control = document.getElementById(id);
        if (control) control.value = "";
      });
      ownerSelect.value = "";
      leadState.page = 1;
      renderAdminLeads();
    });
    document
      .getElementById("adminLeadPagination")
      ?.addEventListener("click", (event) => {
        const button = event.target.closest("[data-lead-page]");
        if (!button || button.disabled) return;
        leadState.page = Number(button.dataset.leadPage);
        renderAdminLeads();
      });
    document
      .getElementById("adminLeadPagination")
      ?.addEventListener("change", (event) => {
        if (event.target.id !== "adminLeadPageSize") return;
        leadState.limit = Number(event.target.value);
        leadState.page = 1;
        renderAdminLeads();
      });
    document
      .getElementById("totalLeadsTable")
      ?.addEventListener("click", (event) => {
        const deleteButton = event.target.closest("[data-interest-delete]");
        if (deleteButton) {
          const item = leadState.rows.find(
            (row) => String(row._id) === deleteButton.dataset.interestDelete,
          );
          if (
            !item ||
            !window.confirm(
              `Remove the interested response for “${item.name || "this lead"}”? The original lead will remain.`,
            )
          )
            return;
          call(`/admin/interested-leads/${item._id}`, { method: "DELETE" })
            .then(() => {
              window.toastr?.success("Interested lead record deleted.");
              renderAdminLeads();
            })
            .catch((error) =>
              window.toastr?.error(
                error.message || "Unable to delete interested lead record.",
              ),
            );
          return;
        }
        const button = event.target.closest("[data-interest-view]");
        if (!button) return;
        const item = leadState.rows[Number(button.dataset.interestView)];
        if (!item) return;
        const location =
          [item.city, item.state, item.country].filter(Boolean).join(", ") ||
          "—";
        const details = `Name: ${item.name || "—"}\nEmail: ${item.leadId?.email || "—"}\nMobile: ${item.mobileNumber || "—"}\nCompany: ${item.companyName || item.leadId?.company || "—"}\nLocation: ${location}\nSequence: ${item.sequenceId?.subject || "—"}\nSubmitted: ${sequenceDate(item.submittedAt)}`;
        if (window.Swal)
          Swal.fire({
            title: "Interested lead details",
            text: details,
            icon: "info",
          });
        else window.alert(details);
      });
  }

  async function renderAdminSequences() {
    const table = document.getElementById("userMasterList");
    if (!table) return;
    document
      .querySelector(".main-title")
      ?.replaceChildren(document.createTextNode("Sequences — All Users"));
    try {
      const search =
        document.getElementById("adminSequenceSearch")?.value.trim() || "";
      const userId = document.getElementById("adminSequenceOwner")?.value || "";
      const businessType =
        document.getElementById("adminSequenceBusinessType")?.value || "";
      const statusValue =
        document.getElementById("adminSequenceStatus")?.value || "";
      const range = dateRange(
        document.getElementById("adminSequenceDateRange")?.value || "",
      );
      const query = new URLSearchParams({
        limit: String(sequenceState.limit),
        page: String(sequenceState.page),
      });
      if (search) query.set("search", search);
      if (userId) query.set("userId", userId);
      if (businessType) query.set("businessType", businessType);
      if (statusValue) query.set("status", statusValue);
      Object.entries(range).forEach(([key, value]) => query.set(key, value));
      const data = await call(`/admin/sequences?${query}`);
      const rows = data.data || [];
      sequenceState.rows = rows;
      const typeSelect = document.getElementById("adminSequenceBusinessType");
      if (typeSelect && !typeSelect.dataset.optionsLoaded) {
        typeSelect.insertAdjacentHTML(
          "beforeend",
          (data.filterOptions?.businessTypes || [])
            .map((type) => `<option value="${esc(type)}">${esc(type)}</option>`)
            .join(""),
        );
        typeSelect.dataset.optionsLoaded = "true";
      }
      const header = table.tHead?.rows[0];
      if (header)
        header.innerHTML =
          "<th>#</th><th>Subject</th><th>Variant</th><th>Gap Days</th><th>Business Type</th><th>Status</th><th>Owner</th><th>Created At</th><th>Actions</th>";
      let body =
        table.tBodies[0] || table.appendChild(document.createElement("tbody"));
      body.innerHTML = rows.length
        ? rows
            .map((item, index) => {
              const displayOwner =
                item.owner?.name || item.userId?.email || "—";
              const variant = String(item.variant || "A").toUpperCase();
              const deleteAction = sequenceState.canDelete
                ? `<button class="sequence-action delete" data-sequence-action="delete" data-id="${esc(item._id)}" title="Delete"><i class="far fa-trash-alt"></i></button>`
                : "";
              return `<tr><td class="sequence-row-no">${(sequenceState.page - 1) * sequenceState.limit + index + 1}</td><td class="sequence-subject" title="${esc(item.subject)}">${esc(item.subject || "—")}</td><td><span class="sequence-variant ${variant === "B" ? "variant-b" : ""}">${esc(variant)}</span></td><td>${esc(item.gapDays ?? 0)}</td><td>${esc(item.businessType || "—")}</td><td>${sequenceStatus(item.status)}</td><td><span class="sequence-owner"><span class="sequence-owner-avatar ${ownerTone(displayOwner)}">${esc(initials(displayOwner))}</span>${esc(displayOwner)}</span></td><td><span class="sequence-date"><i class="far fa-calendar-alt"></i>${esc(sequenceDate(item.createdAt))}</span></td><td><button class="sequence-action" data-sequence-action="view" data-id="${esc(item._id)}" title="View"><i class="fas fa-eye"></i></button><button class="sequence-action" data-sequence-action="edit" data-id="${esc(item._id)}" title="Edit"><i class="fas fa-pen"></i></button><button class="sequence-action" data-sequence-action="copy" data-id="${esc(item._id)}" title="Copy content"><i class="far fa-copy"></i></button>${deleteAction}</td></tr>`;
            })
            .join("")
        : '<tr><td colspan="9" class="text-center py-5 text-muted">No sequences found.</td></tr>';
      renderSequencePagination(data.pagination || {});
    } catch (error) {
      setEmpty(table, 9, error.message);
    }
  }

  function renderSequencePagination(pagination) {
    const host = document.getElementById("adminSequencePagination");
    if (!host) return;
    const total = Number(pagination.total || 0);
    const pages = Math.max(Number(pagination.totalPages || 1), 1);
    const page = Number(pagination.page || sequenceState.page);
    sequenceState.page = page;
    const pageButtons = Array.from(
      { length: Math.min(pages, 5) },
      (_, index) => {
        const pageNumber = index + 1;
        return `<button type="button" class="${pageNumber === page ? "active" : ""}" data-sequence-page="${pageNumber}">${pageNumber}</button>`;
      },
    ).join("");
    host.innerHTML = `<span>Showing ${total ? (page - 1) * sequenceState.limit + 1 : 0} to ${Math.min(page * sequenceState.limit, total)} of ${total} sequences</span><span class="sequence-pages"><button type="button" data-sequence-page="${page - 1}" ${page <= 1 ? "disabled" : ""}><i class="fas fa-chevron-left"></i></button>${pageButtons}<button type="button" data-sequence-page="${page + 1}" ${page >= pages ? "disabled" : ""}><i class="fas fa-chevron-right"></i></button><select class="sequence-page-size" id="adminSequencePageSize"><option value="10" ${sequenceState.limit === 10 ? "selected" : ""}>10 / page</option><option value="25" ${sequenceState.limit === 25 ? "selected" : ""}>25 / page</option><option value="50" ${sequenceState.limit === 50 ? "selected" : ""}>50 / page</option></select></span>`;
  }

  async function initialiseSequenceFilters() {
    const ownerSelect = document.getElementById("adminSequenceOwner");
    if (!ownerSelect || ownerSelect.dataset.backendReady === "true") return;
    ownerSelect.dataset.backendReady = "true";
    try {
      const usersResponse = await call("/admin/users");
      const users = usersResponse.data || [];
      const currentUser = users.find(
        (user) => String(user._id) === String(usersResponse.currentUserId),
      );
      sequenceState.canDelete =
        currentUser?.accessRights?.deleteSequence !== false;
      const options = users
        .map((user) => {
          const name =
            `${user.firstName || ""} ${user.lastName || ""}`.trim() ||
            user.email;
          return `<option value="${esc(user._id)}">${esc(name)}${user.email ? ` — ${esc(user.email)}` : ""}</option>`;
        })
        .join("");
      ownerSelect.insertAdjacentHTML("beforeend", options);
    } catch (_) {
      // The table still works without the optional owner dropdown.
    }

    let searchTimer;
    document
      .getElementById("adminSequenceSearch")
      ?.addEventListener("input", () => {
        window.clearTimeout(searchTimer);
        searchTimer = window.setTimeout(() => {
          sequenceState.page = 1;
          renderAdminSequences();
        }, 300);
      });
    const refreshFilters = () => {
      sequenceState.page = 1;
      renderAdminSequences();
    };
    ownerSelect.addEventListener("change", refreshFilters);
    document
      .getElementById("adminSequenceStatus")
      ?.addEventListener("change", refreshFilters);
    document
      .getElementById("adminSequenceBusinessType")
      ?.addEventListener("change", refreshFilters);
    document
      .getElementById("adminSequenceDateRange")
      ?.addEventListener("change", refreshFilters);
    document
      .getElementById("clear_filters")
      ?.addEventListener("click", (event) => {
        event.preventDefault();
        const search = document.getElementById("adminSequenceSearch");
        const statusSelect = document.getElementById("adminSequenceStatus");
        const businessSelect = document.getElementById(
          "adminSequenceBusinessType",
        );
        const dateSelect = document.getElementById("adminSequenceDateRange");
        if (search) search.value = "";
        ownerSelect.value = "";
        if (statusSelect) statusSelect.value = "";
        if (businessSelect) businessSelect.value = "";
        if (dateSelect) dateSelect.value = "";
        sequenceState.page = 1;
        renderAdminSequences();
      });

    document
      .getElementById("userMasterList")
      ?.addEventListener("click", async (event) => {
        const action = event.target.closest("[data-sequence-action]");
        if (!action) return;
        const item = sequenceState.rows.find(
          (row) => String(row._id) === action.dataset.id,
        );
        if (!item) return;
        const type = action.dataset.sequenceAction;
        if (type === "copy") {
          await navigator.clipboard.writeText(
            item.content || item.subject || "",
          );
          window.toastr?.success("Sequence content copied.");
          return;
        }
        if (type === "delete") {
          if (!window.confirm(`Delete “${item.subject}”?`)) return;
          await call(`/admin/sequences/${item._id}`, { method: "DELETE" });
          window.toastr?.success("Sequence deleted.");
          renderAdminSequences();
          return;
        }
        const modalId = "adminSequenceDetailsModal";
        document.getElementById(modalId)?.remove();
        const edit = type === "edit";
        const modal = document.createElement("div");
        modal.id = modalId;
        modal.className = "modal fade";
        modal.tabIndex = -1;
        modal.innerHTML = `<div class="modal-dialog modal-lg modal-dialog-centered"><form class="modal-content"><div class="modal-header"><h5 class="modal-title">${edit ? "Edit sequence" : "Sequence details"}</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body"><div class="row g-3"><div class="col-md-8"><label class="form-label">Subject</label><input class="form-control" name="subject" value="${esc(item.subject)}" ${edit ? "" : "readonly"}></div><div class="col-md-4"><label class="form-label">Variant</label><input class="form-control" name="variant" value="${esc(item.variant || "A")}" ${edit ? "" : "readonly"}></div><div class="col-md-4"><label class="form-label">Gap days</label><input class="form-control" name="gapDays" type="number" min="0" value="${esc(item.gapDays || 0)}" ${edit ? "" : "readonly"}></div><div class="col-md-4"><label class="form-label">Business type</label><input class="form-control" name="businessType" value="${esc(item.businessType)}" ${edit ? "" : "readonly"}></div><div class="col-md-4"><label class="form-label">Status</label><select class="form-select" name="status" ${edit ? "" : "disabled"}>${["draft", "active", "paused", "completed"].map((value) => `<option value="${value}" ${item.status === value ? "selected" : ""}>${value[0].toUpperCase() + value.slice(1)}</option>`).join("")}</select></div><div class="col-12"><label class="form-label">Content</label><textarea class="form-control" rows="9" name="content" ${edit ? "" : "readonly"}>${esc(item.content || "")}</textarea></div></div></div><div class="modal-footer"><button type="button" class="btn btn-light" data-bs-dismiss="modal">Close</button>${edit ? '<button type="submit" class="btn btn-primary">Save changes</button>' : ""}</div></form></div>`;
        document.body.append(modal);
        if (edit)
          modal
            .querySelector("form")
            .addEventListener("submit", async (submitEvent) => {
              submitEvent.preventDefault();
              const form = new FormData(submitEvent.currentTarget);
              await call(`/admin/sequences/${item._id}`, {
                method: "PATCH",
                body: JSON.stringify(Object.fromEntries(form)),
              });
              bootstrap.Modal.getInstance(modal).hide();
              window.toastr?.success("Sequence updated.");
              renderAdminSequences();
            });
        bootstrap.Modal.getOrCreateInstance(modal).show();
      });

    document
      .getElementById("adminSequencePagination")
      ?.addEventListener("click", (event) => {
        const button = event.target.closest("[data-sequence-page]");
        if (!button || button.disabled) return;
        sequenceState.page = Number(button.dataset.sequencePage);
        renderAdminSequences();
      });
    document
      .getElementById("adminSequencePagination")
      ?.addEventListener("change", (event) => {
        if (event.target.id !== "adminSequencePageSize") return;
        sequenceState.limit = Number(event.target.value);
        sequenceState.page = 1;
        renderAdminSequences();
      });
  }
  document.addEventListener("DOMContentLoaded", () => {
    initialiseLeadFilters().finally(renderAdminLeads);
    initialiseSequenceFilters().finally(renderAdminSequences);
  });
})();
