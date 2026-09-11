(function () {
  "use strict";
  const isLocal = ["localhost", "127.0.0.1"].includes(location.hostname);
  const apiBase =
    localStorage.getItem("highCustomApiBase") ||
    (isLocal
      ? "http://localhost:3000/api"
      : "https://high-custom-app.onrender.com/api");
  const token = localStorage.getItem("highCustomAdminToken");
  const path = location.pathname.toLowerCase();
  const escapeHtml = (value) =>
    String(value ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  const date = (value) =>
    value
      ? new Date(value).toLocaleString("en-GB", {
          dateStyle: "medium",
          timeStyle: "short",
        })
      : "—";
  const find = (selector, root = document) => root.querySelector(selector);
  if (!token) {
    location.replace("/admin-login.html");
    return;
  }

  async function request(url, options = {}) {
    const isForm = options.body instanceof FormData;
    const headers = {
      Accept: "application/json",
      Authorization: `Bearer ${token}`,
      ...(options.headers || {}),
    };
    if (!isForm && options.body) headers["Content-Type"] = "application/json";
    const response = await fetch(`${apiBase}${url}`, { ...options, headers });
    const data = await response.json().catch(() => ({}));
    if (response.status === 401 || response.status === 403) {
      localStorage.removeItem("highCustomAdminToken");
      location.replace("/admin-login.html?reason=access");
      throw new Error("Your admin session has expired.");
    }
    if (!response.ok || data.success === false)
      throw new Error(data.message || "Request failed.");
    return data;
  }

  function notify(message, error = false) {
    if (window.toastr)
      return error ? toastr.error(message) : toastr.success(message);
    alert(message);
  }
  function action(label, theme, type, id) {
    return `<button type="button" class="btn btn-sm ${theme} me-1" data-admin-action="${type}" data-id="${escapeHtml(id)}">${label}</button>`;
  }
  function addCreateButton(host, label, handler) {
    if (!host || find(".admin-own-create", host)) return;
    const button = document.createElement("button");
    button.type = "button";
    button.className = "btn btn-primary admin-own-create ms-2";
    button.innerHTML = `<i class="fas fa-plus me-2"></i>${label}`;
    button.addEventListener("click", handler);
    host.append(button);
  }
  function openModal(id, title, fields, save, saveLabel = "Save") {
    find("#" + id)?.remove();
    const modal = document.createElement("div");
    modal.id = id;
    modal.className = "modal fade";
    modal.tabIndex = -1;
    modal.innerHTML = `<div class="modal-dialog modal-dialog-centered modal-lg"><form class="modal-content"><div class="modal-header"><h5 class="modal-title">${title}</h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body">${fields}</div><div class="modal-footer"><button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancel</button><button class="btn btn-primary" type="submit">${saveLabel}</button></div></form></div>`;
    document.body.append(modal);
    const instance = bootstrap.Modal.getOrCreateInstance(modal);
    find("form", modal).addEventListener("submit", async (event) => {
      event.preventDefault();
      const button = find('[type="submit"]', modal);
      button.disabled = true;
      try {
        await save(new FormData(event.currentTarget));
        instance.hide();
      } catch (error) {
        notify(error.message, true);
      } finally {
        button.disabled = false;
      }
    });
    instance.show();
  }
  function leadForm(lead = {}) {
    return `<div class="row g-3"><div class="col-md-6"><label class="form-label">Email address</label><input class="form-control" name="email" type="email" required value="${escapeHtml(lead.email)}"></div><div class="col-md-6"><label class="form-label">Company</label><input class="form-control" name="company" value="${escapeHtml(lead.company)}"></div><div class="col-md-6"><label class="form-label">First name</label><input class="form-control" name="firstName" value="${escapeHtml(lead.firstName)}"></div><div class="col-md-6"><label class="form-label">Last name</label><input class="form-control" name="lastName" value="${escapeHtml(lead.lastName)}"></div><div class="col-md-6"><label class="form-label">Business type</label><input class="form-control" name="businessType" value="${escapeHtml(lead.businessType)}"></div><div class="col-md-6"><label class="form-label">Channel</label><select class="form-select" name="type"><option value="Email" ${lead.type !== "WhatsApp" ? "selected" : ""}>Email</option><option value="WhatsApp" ${lead.type === "WhatsApp" ? "selected" : ""}>WhatsApp</option></select></div><div class="col-12 form-check ms-2"><input class="form-check-input" type="checkbox" name="tracking" id="adminLeadTracking" ${lead.tracking !== false ? "checked" : ""}><label class="form-check-label" for="adminLeadTracking">Enable email tracking</label></div></div>`;
  }

  async function sequences() {
    const table = find("#sequencesTable");
    if (!table) return;
    let rows = [];
    const render = async () => {
      rows = (await request("/sequence?limit=100")).data || [];
      find("thead tr", table).innerHTML =
        '<th>Step</th><th>Gap days</th><th>Variant</th><th>Subject</th><th>Business type</th><th>Status</th><th>Created</th><th class="text-end">Actions</th>';
      let body = find("tbody", table);
      if (!body) {
        body = document.createElement("tbody");
        table.append(body);
      }
      body.innerHTML = rows.length
        ? rows
            .map(
              (item) =>
                `<tr><td>${escapeHtml(item.step)}</td><td>${escapeHtml(item.gapDays)}</td><td>${escapeHtml(item.variant)}</td><td>${escapeHtml(item.subject)}</td><td>${escapeHtml(item.businessType)}</td><td><span class="badge bg-${item.status === "active" ? "success" : item.status === "paused" ? "warning text-dark" : "secondary"}">${escapeHtml(item.status)}</span></td><td>${date(item.createdAt)}</td><td class="text-end">${action("Edit", "btn-outline-primary", "edit-sequence", item._id)}${action("Delete", "btn-outline-danger", "delete-sequence", item._id)}</td></tr>`,
            )
            .join("")
        : '<tr><td colspan="8" class="text-center py-5">No sequences created yet.</td></tr>';
    };
    table.addEventListener("click", async (event) => {
      const button = event.target.closest("[data-admin-action]");
      if (!button) return;
      const item = rows.find((row) => String(row._id) === button.dataset.id);
      if (!item) return;
      if (button.dataset.adminAction === "delete-sequence") {
        if (!confirm(`Delete the sequence “${item.subject}”? `)) return;
        try {
          await request("/sequence/" + item._id, { method: "DELETE" });
          notify("Sequence deleted.");
          await render();
        } catch (error) {
          notify(error.message, true);
        }
      }
      if (button.dataset.adminAction === "edit-sequence") {
        const fields = `<div class="row g-3"><div class="col-md-3"><label class="form-label">Step</label><input class="form-control" name="step" type="number" min="1" required value="${escapeHtml(item.step)}"></div><div class="col-md-3"><label class="form-label">Gap days</label><input class="form-control" name="gapDays" type="number" min="0" required value="${escapeHtml(item.gapDays)}"></div><div class="col-md-3"><label class="form-label">Variant</label><input class="form-control" name="variant" maxlength="1" required value="${escapeHtml(item.variant)}"></div><div class="col-md-3"><label class="form-label">Status</label><select class="form-select" name="status">${["draft", "active", "paused", "completed"].map((status) => `<option ${item.status === status ? "selected" : ""}>${status}</option>`).join("")}</select></div><div class="col-md-6"><label class="form-label">Business type</label><input class="form-control" name="businessType" required value="${escapeHtml(item.businessType)}"></div><div class="col-md-6"><label class="form-label">Subject</label><input class="form-control" name="subject" required value="${escapeHtml(item.subject)}"></div><div class="col-12"><label class="form-label">Email content</label><textarea class="form-control" name="content" rows="7" required>${escapeHtml(item.content)}</textarea></div><div class="col-md-6"><label class="form-label">WhatsApp link</label><input class="form-control" name="whatsapp" type="url" value="${escapeHtml(item.actionLinks?.whatsapp?.url)}"></div><div class="col-md-6"><label class="form-label">CTA text</label><input class="form-control" name="ctaText" value="${escapeHtml(item.actionLinks?.cta?.text)}"></div><div class="col-12"><label class="form-label">CTA link</label><input class="form-control" name="ctaUrl" type="url" value="${escapeHtml(item.actionLinks?.cta?.url)}"></div></div>`;
        openModal(
          "adminSequenceEditor",
          "Edit email sequence",
          fields,
          async (form) => {
            const payload = new FormData();
            [
              "step",
              "gapDays",
              "variant",
              "status",
              "businessType",
              "subject",
              "content",
            ].forEach((name) => payload.append(name, form.get(name)));
            payload.set("variant", String(form.get("variant")).toUpperCase());
            payload.append(
              "brand",
              JSON.stringify({
                logoUrl: item.brand?.logoUrl || "",
                logoPosition: item.brand?.logoPosition || "Center",
              }),
            );
            payload.append(
              "heroImage",
              JSON.stringify({
                url: item.heroImage?.url || "",
                link: item.heroImage?.link || "",
              }),
            );
            payload.append("attachment", JSON.stringify(item.attachment || {}));
            payload.append(
              "actionLinks",
              JSON.stringify({
                whatsapp: {
                  enabled: Boolean(form.get("whatsapp")),
                  url: form.get("whatsapp") || "",
                },
                cta: {
                  enabled: Boolean(form.get("ctaText") && form.get("ctaUrl")),
                  text: form.get("ctaText") || "",
                  url: form.get("ctaUrl") || "",
                },
              }),
            );
            payload.append("tracking", JSON.stringify({ enabled: true }));
            await request("/sequence/" + item._id, {
              method: "PUT",
              body: payload,
            });
            notify("Sequence updated.");
            await render();
          },
          "Update sequence",
        );
      }
    });
    await render();
  }

  async function leads() {
    const body = find("#leadTableBody");
    if (!body) return;
    const table = body.closest("table");
    let rows = [];
    const leadEntryForm = find("#leadForm");
    const businessTypeSelect = find("#leadType");
    const loadBusinessTypes = async () => {
      if (!businessTypeSelect) return;
      const selected = businessTypeSelect.value;
      const types = (await request("/business-types")).data || [];
      businessTypeSelect.innerHTML =
        '<option value="" selected disabled>Select Business Type</option>' +
        (types.length
          ? types
              .map(
                (item) =>
                  `<option value="${escapeHtml(item.name)}">${escapeHtml(item.name)}</option>`,
              )
              .join("")
          : '<option value="" disabled>No business types available</option>');
      if (types.some((item) => item.name === selected))
        businessTypeSelect.value = selected;
    };
    const render = async () => {
      rows = (await request("/leads/get-leads")).leads || [];
      find("thead tr", table).innerHTML =
        '<th>Email</th><th>Name</th><th>Company</th><th>Business type</th><th>Channel</th><th>Tracking</th><th>Added</th><th class="text-end">Actions</th>';
      body.innerHTML = rows.length
        ? rows
            .map(
              (item) =>
                `<tr><td>${escapeHtml(item.email)}</td><td>${escapeHtml(`${item.firstName || ""} ${item.lastName || ""}`.trim() || "—")}</td><td>${escapeHtml(item.company || "—")}</td><td>${escapeHtml(item.businessType || "—")}</td><td>${escapeHtml(item.type || "Email")}</td><td>${escapeHtml(item.trackingStatus || (item.tracking ? "Pending" : "Skip"))}</td><td>${date(item.addedDate || item.createdAt)}</td><td class="text-end">${action("Edit", "btn-outline-primary", "edit-lead", item._id)}${action("Delete", "btn-outline-danger", "delete-lead", item._id)}</td></tr>`,
            )
            .join("")
        : '<tr><td colspan="8" class="text-center py-5">No leads added yet.</td></tr>';
      find("#paginationContainer")?.replaceChildren();
    };

    // The New Lead Entry card is the primary lead-creation flow on this page.
    // Its original template used a placeholder request; connect it to the API.
    window.submitLeadFromButton = async () => {
      const payload = {
        email: String(find("#email")?.value || "").trim(),
        firstName: String(find("#name")?.value || "").trim(),
        lastName: String(find("#lastname")?.value || "").trim(),
        company: String(find("#company_name")?.value || "").trim(),
        businessType: String(businessTypeSelect?.value || "").trim(),
        type: "Email",
        tracking: true,
      };
      if (
        !payload.email ||
        !payload.firstName ||
        !payload.lastName ||
        !payload.company ||
        !payload.businessType
      ) {
        notify(
          "Please complete all lead details and select a business type.",
          true,
        );
        return;
      }
      try {
        await request("/leads/create-lead", {
          method: "POST",
          body: JSON.stringify(payload),
        });
        leadEntryForm?.reset();
        await loadBusinessTypes();
        notify("Lead added successfully.");
        await render();
      } catch (error) {
        notify(error.message, true);
      }
    };
    if (leadEntryForm && !leadEntryForm.dataset.adminBackendBound) {
      leadEntryForm.dataset.adminBackendBound = "true";
      leadEntryForm.addEventListener(
        "submit",
        (event) => {
          event.preventDefault();
          window.submitLeadFromButton();
        },
        true,
      );
    }
    addCreateButton(
      find(".main-content") || find(".container-fluid"),
      "Create Lead",
      () =>
        openModal(
          "adminLeadModal",
          "Create lead",
          leadForm(),
          async (form) => {
            const data = Object.fromEntries(form);
            data.tracking = form.get("tracking") === "on";
            await request("/leads/create-lead", {
              method: "POST",
              body: JSON.stringify(data),
            });
            notify("Lead created.");
            await render();
          },
          "Create lead",
        ),
    );
    table.addEventListener("click", async (event) => {
      const button = event.target.closest("[data-admin-action]");
      if (!button) return;
      const item = rows.find((row) => String(row._id) === button.dataset.id);
      if (!item) return;
      if (button.dataset.adminAction === "delete-lead") {
        if (!confirm(`Delete ${item.email}? `)) return;
        try {
          await request("/leads/delete-lead/" + item._id, { method: "DELETE" });
          notify("Lead deleted.");
          await render();
        } catch (error) {
          notify(error.message, true);
        }
      }
      if (button.dataset.adminAction === "edit-lead")
        openModal(
          "adminLeadModal",
          "Edit lead",
          leadForm(item),
          async (form) => {
            const data = Object.fromEntries(form);
            data.tracking = form.get("tracking") === "on";
            await request("/leads/update-lead/" + item._id, {
              method: "PUT",
              body: JSON.stringify(data),
            });
            notify("Lead updated.");
            await render();
          },
          "Update lead",
        );
    });
    window.loadLeads = render;
    try {
      await Promise.all([render(), loadBusinessTypes()]);
    } catch (error) {
      notify(error.message, true);
    }
  }

  function collectionPage({
    root,
    url,
    label,
    createHost,
    form,
    columns,
    editMethod = "PATCH",
  }) {
    const host = find(root);
    if (!host) return;
    let rows = [];
    const render = async () => {
      rows = (await request(url)).data || [];
      let panel = find("#adminOwnCollection");
      if (!panel) {
        panel = document.createElement("section");
        panel.id = "adminOwnCollection";
        panel.className = "card shadow-sm mb-4";
        host.prepend(panel);
      }
      panel.innerHTML = `<div class="card-header d-flex justify-content-between align-items-center"><strong>Your ${label}</strong><span class="badge bg-primary">${rows.length}</span></div><div class="table-responsive"><table class="table mb-0"><thead><tr>${columns.headers.map((header) => `<th>${header}</th>`).join("")}<th class="text-end">Actions</th></tr></thead><tbody>${
        rows.length
          ? rows
              .map(
                (item) =>
                  `<tr>${columns
                    .cells(item)
                    .map((cell) => `<td>${cell}</td>`)
                    .join(
                      "",
                    )}<td class="text-end">${action("Edit", "btn-outline-primary", "edit", item._id)}${action("Delete", "btn-outline-danger", "delete", item._id)}</td></tr>`,
              )
              .join("")
          : `<tr><td colspan="${columns.headers.length + 1}" class="text-center py-4">No ${label.toLowerCase()} created yet.</td></tr>`
      }</tbody></table></div>`;
      panel.onclick = async (event) => {
        const button = event.target.closest("[data-admin-action]");
        if (!button) return;
        const item = rows.find((row) => String(row._id) === button.dataset.id);
        if (!item) return;
        if (button.dataset.adminAction === "delete") {
          if (!confirm(`Delete “${item.name}”? `)) return;
          try {
            await request(url + "/" + item._id, { method: "DELETE" });
            notify(`${label.slice(0, -1)} deleted.`);
            await render();
          } catch (error) {
            notify(error.message, true);
          }
        }
        if (button.dataset.adminAction === "edit")
          openModal(
            "adminCollectionModal",
            `Edit ${label.slice(0, -1)}`,
            form(item),
            async (data) => {
              await request(url + "/" + item._id, {
                method: editMethod,
                body: JSON.stringify(Object.fromEntries(data)),
              });
              notify(`${label.slice(0, -1)} updated.`);
              await render();
            },
            "Update",
          );
      };
    };
    addCreateButton(find(createHost), "Add " + label.slice(0, -1), () =>
      openModal(
        "adminCollectionModal",
        "Add " + label.slice(0, -1),
        form(),
        async (data) => {
          await request(url, {
            method: "POST",
            body: JSON.stringify(Object.fromEntries(data)),
          });
          notify(`${label.slice(0, -1)} created.`);
          await render();
        },
        "Create",
      ),
    );
    return render();
  }

  async function businessTypes() {
    return collectionPage({
      root: ".business-wrapper",
      url: "/business-types",
      label: "Business Types",
      createHost: ".business-card .text-center",
      form: (item) =>
        `<label class="form-label">Business type</label><input class="form-control" name="name" placeholder="Example: Retail" required value="${escapeHtml(item?.name)}">`,
      columns: {
        headers: ["Business type", "Created"],
        cells: (item) => [escapeHtml(item.name), date(item.createdAt)],
      },
    });
  }
  async function tracking() {
    const table = find("#campaignTable");
    if (!table) return;
    const rows =
      (await request("/email-tracking/report?limit=100")).deliveries || [];
    if (window.jQuery?.fn.DataTable?.isDataTable(table))
      window.jQuery(table).DataTable().destroy();
    find("thead tr", table).innerHTML =
      "<th>#</th><th>Lead</th><th>Email</th><th>Step</th><th>Subject</th><th>Status</th><th>Sent</th><th>Opened</th><th>Replied</th>";
    find("tbody", table).innerHTML = rows.length
      ? rows
          .map(
            (item, index) =>
              `<tr><td>${index + 1}</td><td>${escapeHtml(`${item.leadId?.firstName || ""} ${item.leadId?.lastName || ""}`.trim() || "—")}</td><td>${escapeHtml(item.leadId?.email || item.email)}</td><td>${escapeHtml(item.step)}</td><td>${escapeHtml(item.sequenceId?.subject)}</td><td>${escapeHtml(item.responseStatus || (item.openedAt ? "Opened" : item.status))}</td><td>${date(item.sentAt)}</td><td>${date(item.openedAt)}</td><td>${date(item.repliedAt)}</td></tr>`,
          )
          .join("")
      : '<tr><td colspan="9" class="text-center py-5">No email tracking records yet.</td></tr>';
    if (window.jQuery?.fn.DataTable)
      window
        .jQuery(table)
        .DataTable({ pageLength: 10, destroy: true, order: [[6, "desc"]] });
  }

  // The Social Links page already has a rich UI. These bindings replace its old
  // placeholder requests and keep that exact screen connected to the API.
  async function connectSocialQuickLinks() {
    if (!find("#socialAccordion, #ecommerceAccordion, #paymentAccordion"))
      return;
    let links = [];
    const refresh = async () => {
      // Clear Blade-template placeholder values immediately, even if a request fails.
      document
        .querySelectorAll(
          "#socialAccordion .link-input, #ecommerceAccordion .link-input, #paymentAccordion .link-input",
        )
        .forEach((input) => {
          if (input.value === "—") input.value = "";
        });
      links = (await request("/social-links")).data || [];
      const presetPlatforms = new Set(
        [
          ...document.querySelectorAll(
            "#socialAccordion .quick-link-item .qr-platform-checkbox, #ecommerceAccordion .quick-link-item .qr-platform-checkbox, #paymentAccordion .quick-link-item .qr-platform-checkbox",
          ),
        ].map((box) => String(box.dataset.platform || "").toLowerCase()),
      );
      document.querySelectorAll(".quick-link-item").forEach((row) => {
        const input = find(".link-input", row);
        const platform =
          row.querySelector(".qr-platform-checkbox")?.dataset.platform || "";
        const link = links.find(
          (item) =>
            String(item.platform || item.name).toLowerCase() ===
            platform.toLowerCase(),
        );
        // Preset rows are templates only. Do not display them until a real
        // saved link for that platform is returned by the backend.
        if (
          !link &&
          row.closest(
            "#socialAccordion, #ecommerceAccordion, #paymentAccordion",
          )
        ) {
          row.hidden = true;
          if (input) input.value = "";
          return;
        }
        row.hidden = false;
        const checkbox = find(".qr-platform-checkbox", row);
        if (checkbox) checkbox.checked = link?.selected === true;
        if (!input) return;
        input.value = link?.url || "";
        const copy = find(".tracking-copy-btn", row);
        if (copy) copy.dataset.trackingUrl = link?.trackingTarget || "";
        const count = find(".open-count", row);
        if (count)
          count.textContent = String(
            (link?.linkClicks || 0) + (link?.qrScans || 0),
          );
      });
      ["socialAccordion", "ecommerceAccordion", "paymentAccordion"].forEach(
        (id) => {
          const card = find("#" + id);
          const badge = find(".accordion-button .badge", card);
          if (badge)
            badge.textContent = String(
              [...card.querySelectorAll(".quick-link-item")].filter(
                (row) => !row.hidden,
              ).length,
            );
        },
      );
      const customLinks = links.filter(
        (item) =>
          !presetPlatforms.has(
            String(item.platform || item.name || "").toLowerCase(),
          ),
      );
      const customContainer = find("#customLinksContainer");
      if (customContainer) {
        customContainer.innerHTML = customLinks.length
          ? customLinks
              .map(
                (
                  item,
                ) => `<div class="app-link quick-link-item" data-custom-link-id="${escapeHtml(item._id)}">
          <input type="checkbox" class="qr-platform-checkbox" data-platform="${escapeHtml(item.platform || item.name)}" ${item.selected === true ? "checked" : ""}>
          <i class="fas fa-link" style="color:#667eea;font-size:20px;width:30px;"></i>
          <strong style="min-width:120px;">${escapeHtml(item.name || item.platform)}</strong>
          <a class="link-input" href="${escapeHtml(item.url)}" target="_blank" rel="noopener">${escapeHtml(item.url)}</a>
          <button type="button" onclick="editCustomPlatform('${escapeHtml(item._id)}')" class="save-btn-sm"><i class="fas fa-pen"></i> Edit</button>
          <button type="button" onclick="copyTrackingLink(this)" class="copy-btn-sm tracking-copy-btn" data-tracking-url="${escapeHtml(item.trackingTarget || "")}"><i class="fas fa-copy"></i> Copy</button>
          <button type="button" class="count-btn-sm" disabled><i class="fas fa-chart-line"></i><span class="open-count">${escapeHtml((item.linkClicks || 0) + (item.qrScans || 0))}</span></button>
          <button type="button" onclick="deleteCustomPlatform('${escapeHtml(item._id)}')" class="save-btn-sm" style="background:#dc3545;"><i class="fas fa-trash"></i> Delete</button>
        </div>`,
              )
              .join("")
          : '<p class="text-muted mb-0" id="customLinksEmpty">No custom links added yet.</p>';
      }
      const customCount = find("#customLinksCount");
      if (customCount) customCount.textContent = String(customLinks.length);
    };
    window.saveQuickLink = async (inputId, platform, button) => {
      const input = find("#" + inputId);
      const url = String(input?.value || "").trim();
      if (!/^https?:\/\//i.test(url)) {
        notify("Please enter a complete URL starting with https://", true);
        return;
      }
      button && (button.disabled = true);
      try {
        const existing = links.find(
          (item) =>
            String(item.platform || item.name).toLowerCase() ===
            String(platform).toLowerCase(),
        );
        if (existing)
          await request("/social-links/" + existing._id, {
            method: "PATCH",
            body: JSON.stringify({ name: platform, url }),
          });
        else
          await request("/social-links", {
            method: "POST",
            body: JSON.stringify({ name: platform, platform, url }),
          });
        notify(platform + " link saved.");
        await refresh();
      } catch (error) {
        notify(error.message, true);
      } finally {
        button && (button.disabled = false);
      }
    };
    window.copyTrackingLink = async (button) => {
      const url = String(button?.dataset.trackingUrl || "").trim();
      if (!url) {
        notify("Save this link first to generate its tracking URL.", true);
        return;
      }
      try {
        await navigator.clipboard.writeText(url);
        notify("Tracking link copied.");
      } catch (_) {
        window.prompt("Copy this tracking link:", url);
      }
    };
    window.addCustomPlatform = async (button) => {
      const nameInput = find("#newPlatformName");
      const urlInput = find("#newPlatformUrl");
      const name = String(nameInput?.value || "").trim();
      const url = String(urlInput?.value || "").trim();
      if (!name || !/^https?:\/\//i.test(url)) {
        notify(
          "Enter a platform name and a complete URL starting with https://",
          true,
        );
        return;
      }
      const original = button?.innerHTML;
      if (button) button.disabled = true;
      try {
        await request("/social-links", {
          method: "POST",
          body: JSON.stringify({ name, platform: name, url }),
        });
        nameInput.value = "";
        urlInput.value = "";
        notify("Custom link added.");
        await refresh();
        bootstrap.Collapse.getOrCreateInstance(find("#customLinksCollapse"), {
          toggle: false,
        }).show();
      } catch (error) {
        notify(error.message, true);
      } finally {
        if (button) {
          button.disabled = false;
          button.innerHTML = original;
        }
      }
    };
    window.deleteCustomPlatform = async (id) => {
      if (!confirm("Delete this custom link?")) return;
      try {
        await request("/social-links/" + id, { method: "DELETE" });
        notify("Custom link deleted.");
        await refresh();
      } catch (error) {
        notify(error.message, true);
      }
    };
    window.editCustomPlatform = async (id) => {
      const item = links.find((link) => String(link._id) === String(id));
      if (!item) return;
      const name = window.prompt("Link name", item.name || item.platform || "");
      if (name === null) return;
      const url = window.prompt("Link URL", item.url || "");
      if (url === null) return;
      if (!String(name).trim() || !/^https?:\/\//i.test(String(url).trim())) {
        notify("Enter a name and a complete URL starting with https://", true);
        return;
      }
      try {
        await request("/social-links/" + id, {
          method: "PATCH",
          body: JSON.stringify({
            name: String(name).trim(),
            url: String(url).trim(),
          }),
        });
        notify("Custom link updated.");
        await refresh();
      } catch (error) {
        notify(error.message, true);
      }
    };
    window.addMultipleQR = async () => {
      const selected = [
        ...document.querySelectorAll(".qr-platform-checkbox:checked"),
      ].map((box) => box.dataset.platform.toLowerCase());
      const ids = links
        .filter((item) =>
          selected.includes(String(item.platform || item.name).toLowerCase()),
        )
        .map((item) => item._id);
      if (!ids.length) {
        notify("Select one or more links before generating QR codes.", true);
        return;
      }
      try {
        await request("/social-links/generate-qr", {
          method: "POST",
          body: JSON.stringify({ linkIds: ids }),
        });
        notify("QR codes generated.");
        await refresh();
      } catch (error) {
        notify(error.message, true);
      }
    };
    // This is the same selection state Flutter stores before opening the
    // Link screen.  Selected saved links become available as Action Links.
    document.addEventListener("change", async (event) => {
      const checkbox = event.target.closest(".qr-platform-checkbox");
      if (!checkbox) return;
      const platform = String(checkbox.dataset.platform || "").toLowerCase();
      const link = links.find(
        (item) =>
          String(item.platform || item.name || "").toLowerCase() === platform,
      );
      if (!link?._id) return;
      try {
        await request("/social-links/" + link._id, {
          method: "PATCH",
          body: JSON.stringify({ selected: checkbox.checked }),
        });
      } catch (error) {
        checkbox.checked = !checkbox.checked;
        notify(error.message, true);
      }
    });
    const renderQrList = async () => {
      const qrs = (await request("/social-links/qr")).data || [];
      const host = find("#multipleQrContainer");
      if (host)
        host.innerHTML = qrs.length
          ? qrs
              .map(
                (item) =>
                  `<div class="card mb-3"><div class="card-body d-flex align-items-center gap-3 flex-wrap"><img src="${escapeHtml(item.qrCode)}" alt="${escapeHtml(item.name)} QR" style="width:120px;height:120px;object-fit:contain"><div class="flex-grow-1"><h6 class="mb-1">${escapeHtml(item.qrTitle || item.name)}</h6><small class="text-muted d-block text-break">${escapeHtml(item.qrTarget || "")}</small></div>${item.fixedCard ? "" : `<button class="btn btn-outline-danger btn-sm" type="button" data-admin-delete-qr="${escapeHtml(item._id)}">Delete QR</button>`}</div></div>`,
              )
              .join("")
          : '<p class="text-muted mb-0">No QR codes generated yet.</p>';
      host?.querySelectorAll("[data-admin-delete-qr]").forEach((button) =>
        button.addEventListener("click", async () => {
          if (!confirm("Delete this QR code?")) return;
          try {
            await request(
              "/social-links/" + button.dataset.adminDeleteQr + "/qr",
              { method: "DELETE" },
            );
            notify("QR code deleted.");
            await renderQrList();
          } catch (error) {
            notify(error.message, true);
          }
        }),
      );
    };
    window.refreshAllQRs = renderQrList;
    window.deleteQR = async (id) => {
      if (!confirm("Delete this QR code?")) return;
      try {
        await request("/social-links/" + id + "/qr", { method: "DELETE" });
        notify("QR code deleted.");
        await renderQrList();
      } catch (error) {
        notify(error.message, true);
      }
    };
    const viewAllQrButton = find("#viewAllQRBtn");
    const cleanViewAllQrButton = viewAllQrButton?.cloneNode(true);
    if (viewAllQrButton && cleanViewAllQrButton)
      viewAllQrButton.replaceWith(cleanViewAllQrButton);
    cleanViewAllQrButton?.addEventListener("click", async () => {
      try {
        await renderQrList();
        bootstrap.Modal.getOrCreateInstance(find("#multipleQRModal")).show();
      } catch (error) {
        notify(error.message, true);
      }
    });
    await refresh();
  }

  // Uses the exact Business Card endpoints and field structure used by Flutter.
  async function connectBusinessCard() {
    const originalModal = find("#businessCardModal");
    if (!originalModal) return;
    // The original converted template still has placeholder jQuery handlers.
    // Replacing the modal removes those handlers before backend handlers are added.
    const modal = originalModal.cloneNode(true);
    originalModal.replaceWith(modal);
    const form = find("#businessCardForm", modal);
    const saveButton = find("#generateBusinessCard", modal);
    const actions = find("#cardActions", modal);
    let hasSavedCard = false;
    let savedQrCode = "";
    if (!find("#adminBusinessCardPreviewStyle")) {
      const style = document.createElement("style");
      style.id = "adminBusinessCardPreviewStyle";
      style.textContent = `.admin-bc{position:relative;overflow:hidden;aspect-ratio:1.75;background:#fffdf8;color:#06143d;text-align:left;font-family:Arial,sans-serif;box-shadow:0 14px 28px rgba(6,20,61,.16)}.admin-bc:before{content:'';position:absolute;right:-4%;top:0;width:43%;height:52%;background:#06143d;clip-path:polygon(8% 0,75% 0,100% 28%,100% 76%,68% 100%,27% 45%,47% 19%)}.admin-bc:after{content:'';position:absolute;right:0;bottom:0;width:34%;height:43%;background:#c9c5e2;clip-path:polygon(100% 0,100% 100%,30% 100%)}.admin-bc-brand{position:absolute;left:4.2%;top:5%;width:43%;font-size:clamp(14px,2.5vw,31px);font-weight:800;letter-spacing:2px;line-height:1.05}.admin-bc-brand small{display:block;font-size:35%;letter-spacing:3px;margin-top:5px}.admin-bc-main{position:absolute;left:5%;top:36%;width:55%;z-index:2}.admin-bc-name{font-size:clamp(22px,4.5vw,54px);font-weight:800;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.admin-bc-role{font-size:clamp(12px,2.2vw,26px);font-weight:700;margin-top:1%}.admin-bc-wa{display:flex;align-items:center;gap:12px;margin-top:4%;font-size:clamp(14px,3vw,35px);font-weight:800}.admin-bc-icon{display:grid;place-items:center;background:#06143d;color:#fff;width:clamp(28px,5vw,58px);height:clamp(28px,5vw,58px);border-radius:7px;font-size:clamp(15px,2.6vw,32px)}.admin-bc-details{position:absolute;left:5%;bottom:7%;width:56%;z-index:2}.admin-bc-detail{display:flex;align-items:center;gap:10px;border-bottom:2px solid #b6b1d3;padding:1.5% 0;font-size:clamp(9px,1.7vw,21px);font-weight:700}.admin-bc-detail:last-child{border:0}.admin-bc-detail .admin-bc-icon{flex:0 0 auto}.admin-bc-qr{position:absolute;right:7%;top:9%;width:19%;aspect-ratio:1;background:#fff;padding:1%;z-index:3}.admin-bc-qr canvas,.admin-bc-qr img{width:100%!important;height:100%!important;display:block}.admin-bc-scan{position:absolute;right:5.5%;top:45%;width:23%;text-align:center;color:#fff;font-size:clamp(8px,1.5vw,17px);font-weight:800;letter-spacing:1px;z-index:3}`;
      style.textContent += `.admin-bc-main{top:37%;width:54%}.admin-bc-name{font-size:clamp(22px,3.8vw,47px);line-height:1.04}.admin-bc-role{font-size:clamp(13px,2vw,25px);margin-top:1.2%}.admin-bc-wa{margin-top:2.5%;font-size:clamp(14px,2.5vw,31px);line-height:1}.admin-bc-details{bottom:5%;height:25%;display:flex;flex-direction:column;justify-content:space-between}.admin-bc-detail{height:30%;min-height:0;padding:0;font-size:clamp(9px,1.45vw,19px);line-height:1.08;overflow:hidden}.admin-bc-detail .admin-bc-icon{width:clamp(25px,4vw,48px);height:clamp(25px,4vw,48px);font-size:clamp(14px,2vw,26px)}.admin-bc-wa .admin-bc-icon{width:clamp(28px,4vw,50px);height:clamp(28px,4vw,50px)}.admin-bc-scan{top:48%}`;
      document.head.append(style);
    }
    const fieldValue = (name) =>
      String(find(`[name="${name}"]`, form)?.value || "").trim();
    const renderPreview = () => {
      const fullName = fieldValue("full_name") || "Full Name";
      const role = fieldValue("role_name") || "Role / Designation";
      const company = fieldValue("company_name") || "High Custom Jewellers";
      const whatsapp = fieldValue("whatsapp") || "WhatsApp";
      const email = fieldValue("email") || "Email address";
      const address = fieldValue("address") || "Business address";
      const qrLink = fieldValue("qr_links");
      const website = (qrLink || "www.highcustomjewellens.com")
        .replace(/^https?:\/\//i, "")
        .replace(/\/$/, "");
      const preview = find("#cardPreviewContent", modal);
      if (!preview) return;
      preview.style.cssText =
        "display:block;width:100%;min-height:500px;visibility:visible;";
      preview.innerHTML = `<div class="admin-bc" style="display:block;width:100%;min-height:500px;aspect-ratio:1.75;background:#fffdf8;"><div class="admin-bc-brand">${escapeHtml(company)}<small>CRAFTING TIMELESS ELEGANCE</small></div><div class="admin-bc-main"><div class="admin-bc-name">${escapeHtml(fullName)}</div><div class="admin-bc-role">${escapeHtml(role)}</div><div class="admin-bc-wa"><span class="admin-bc-icon"><i class="fab fa-whatsapp"></i></span>${escapeHtml(whatsapp)}</div></div><div class="admin-bc-details"><div class="admin-bc-detail"><span class="admin-bc-icon"><i class="fas fa-map-marker-alt"></i></span>${escapeHtml(address)}</div><div class="admin-bc-detail"><span class="admin-bc-icon"><i class="fas fa-envelope"></i></span>${escapeHtml(email)}</div><div class="admin-bc-detail"><span class="admin-bc-icon"><i class="fas fa-globe"></i></span>${escapeHtml(website)}</div></div><div class="admin-bc-qr" id="adminBusinessCardQr"></div><div class="admin-bc-scan">SCAN TO CONNECT</div></div>`;
      const qrHost = find("#adminBusinessCardQr", preview);
      if (savedQrCode && qrLink)
        qrHost.innerHTML = `<img src="${escapeHtml(savedQrCode)}" alt="QR code">`;
      else if (qrLink && window.QRCode)
        new window.QRCode(qrHost, {
          text: qrLink,
          width: 220,
          height: 220,
          correctLevel: window.QRCode.CorrectLevel.H,
        });
      else
        qrHost.innerHTML =
          '<i class="fas fa-qrcode" style="font-size:42px;padding:25%"></i>';
    };
    // Exposed for the final page-level fallback listener as the old converted
    // template has multiple legacy event handlers.
    window.renderAdminBusinessCardPreview = renderPreview;

    const cardRequest = async (path, options = {}) => {
      const headers = {
        Accept: "application/json",
        Authorization: `Bearer ${token}`,
        ...(options.body ? { "Content-Type": "application/json" } : {}),
      };
      const response = await fetch(apiBase + "/business-card" + path, {
        ...options,
        headers,
      });
      const data = await response.json().catch(() => ({}));
      if (response.status === 401 || response.status === 403) {
        localStorage.removeItem("highCustomAdminToken");
        location.replace("/admin-login.html?reason=access");
        return null;
      }
      if (!response.ok && response.status !== 404)
        throw new Error(data.message || "Business card request failed.");
      return { status: response.status, data };
    };
    const set = (name, value = "") => {
      const input = find(`[name="${name}"]`, form);
      if (input) input.value = value || "";
    };
    const renderActions = () => {
      if (!actions) return;
      actions.innerHTML = hasSavedCard
        ? '<div class="mt-3 text-center"><button type="button" class="btn btn-outline-danger btn-sm" id="deleteBusinessCard"><i class="fas fa-trash me-1"></i> Delete Business Card</button></div>'
        : "";
      find("#deleteBusinessCard", actions)?.addEventListener(
        "click",
        async () => {
          if (!confirm("Delete this business card?")) return;
          try {
            await cardRequest("/delete-businessCard", { method: "DELETE" });
            hasSavedCard = false;
            savedQrCode = "";
            form.reset();
            renderPreview();
            renderActions();
            notify("Business card deleted.");
          } catch (error) {
            notify(error.message, true);
          }
        },
      );
    };
    const load = async () => {
      const result = await cardRequest("/fetch-businessCard");
      if (!result || result.status === 404) {
        hasSavedCard = false;
        savedQrCode = "";
        form.reset();
        renderPreview();
        renderActions();
        return;
      }
      const card = result.data.businessCard || {};
      set("full_name", card.fullName);
      set("role_name", card.role);
      set("company_name", card.companyName);
      set("whatsapp", card.whatsapp);
      set("email", card.email);
      set("qr_links", card.qrLink);
      set("address", card.address);
      hasSavedCard = true;
      savedQrCode = card.qrCode || "";
      renderPreview();
      renderActions();
    };
    form?.addEventListener("input", () => {
      savedQrCode = "";
      renderPreview();
    });
    saveButton?.addEventListener("click", async () => {
      const card = {
        fullName: String(find('[name="full_name"]', form)?.value || "").trim(),
        role: String(find('[name="role_name"]', form)?.value || "").trim(),
        companyName: String(
          find('[name="company_name"]', form)?.value || "",
        ).trim(),
        whatsapp: String(find('[name="whatsapp"]', form)?.value || "")
          .replace(/\D/g, "")
          .replace(/^91(?=\d{10}$)/, ""),
        email: String(find('[name="email"]', form)?.value || "").trim(),
        qrLink: String(find('[name="qr_links"]', form)?.value || "").trim(),
        address: String(find('[name="address"]', form)?.value || "").trim(),
      };
      if (
        Object.values(card).some((value) => !value) ||
        card.whatsapp.length !== 10 ||
        !/^https?:\/\//i.test(card.qrLink)
      ) {
        notify(
          "Complete all details, use a valid 10-digit WhatsApp number, and enter a QR link starting with https://",
          true,
        );
        return;
      }
      const original = saveButton.innerHTML;
      saveButton.disabled = true;
      saveButton.innerHTML =
        '<i class="fas fa-spinner fa-spin me-2"></i>Saving...';
      try {
        const result = await cardRequest(
          hasSavedCard ? "/update-businessCard" : "/create-BusinessCard",
          { method: hasSavedCard ? "PUT" : "POST", body: JSON.stringify(card) },
        );
        hasSavedCard = Boolean(result?.data?.success);
        savedQrCode = result?.data?.businessCard?.qrCode || "";
        renderPreview();
        renderActions();
        notify(result?.data?.message || "Business card saved.");
      } catch (error) {
        notify(error.message, true);
      } finally {
        saveButton.disabled = false;
        saveButton.innerHTML = original;
      }
    });
    window.BusinessCardModalOpen = async () => {
      try {
        await load();
        bootstrap.Modal.getOrCreateInstance(modal).show();
      } catch (error) {
        notify(error.message, true);
      }
    };
  }

  // Link page: company links, selected CTA links and business type are all saved
  // in Business Link Settings for the signed-in Admin account.
  async function connectBusinessLinkSettings() {
    const form = find("#businessForm");
    if (!form) return;
    // Business types are selected here; they are managed elsewhere, so this
    // page intentionally does not show a separate list or an Add button.
    find("#adminOwnCollection")?.remove();
    if (!find("#adminBusinessTypeDropdownStyle")) {
      const style = document.createElement("style");
      style.id = "adminBusinessTypeDropdownStyle";
      style.textContent =
        "#businessForm input,#businessForm .dropdown-header,#businessForm .dropdown-header span{color:#0f172a!important}#businessForm input::placeholder{color:#64748b!important;opacity:1}#businessForm .dropdown-header{background:#fff!important;border-color:#cbd5e1!important}#businessForm .dropdown-header span{font-weight:600}#businessTypeContent{margin-top:8px;background:#fff;border:1px solid #cbd5e1;border-radius:14px;box-shadow:0 14px 30px rgba(15,23,42,.14);padding:7px;position:absolute;z-index:1100}#businessTypeContent .business-type-item{display:block;color:#0f172a;font-weight:700;padding:12px 14px;border-radius:10px}#businessTypeContent .business-type-item:hover,#businessTypeContent .business-type-item.active{background:#eff6ff;color:#2563eb}";
      document.head.append(style);
    }
    let types = [];
    let links = [];
    const applySavedSettings = (settings) => {
      const selectedIds = new Set((settings?.actionLinkIds || []).map(String));
      document.querySelectorAll(".action-link-checkbox").forEach((box) => {
        box.checked = selectedIds.has(String(box.value));
      });
      const whatsapp = find('[name="whatsapp_link"]');
      if (whatsapp && settings?.whatsappUrl)
        whatsapp.value = settings.whatsappUrl;
      updateSelected();
    };
    const updateSelected = () => {
      const checked = [
        ...document.querySelectorAll(".action-link-checkbox:checked"),
      ];
      const list = find("#selectedLinksList");
      const count = find("#selectedCount");
      if (count)
        count.textContent = checked.length
          ? `${checked.length} Link(s) Selected`
          : "Select Links";
      if (list)
        list.innerHTML = checked.length
          ? checked
              .map(
                (box) =>
                  `<span class="badge badge-light d-flex align-items-center p-2" style="background:#404e4ede;font-size:.9rem;border-radius:20px"><span>${escapeHtml(box.dataset.name || "")}</span><i class="fas fa-times ms-2 text-danger remove-link-tag" style="cursor:pointer;font-size:.8rem" data-link-id="${escapeHtml(box.value)}"></i></span>`,
              )
              .join("")
          : '<span id="noSelectedMsg" class="text-muted">No links selected</span>';
    };
    const load = async (businessType = "") => {
      const settingsUrl =
        "/business-link-settings" +
        (businessType
          ? "?businessType=" + encodeURIComponent(businessType)
          : "");
      const result = await Promise.all([
        request("/social-links").then((data) => data.data || []),
        request("/business-types").then((data) => data.data || []),
        request(settingsUrl).then((data) => data.data || null),
      ]);
      [links, types] = result;
      const settings = result[2];
      const choices = find("#dropdownContent");
      // Flutter exposes only saved-and-selected social links here.
      const selectedLinks = links.filter((item) => item.selected === true);
      if (choices)
        choices.innerHTML = selectedLinks.length
          ? selectedLinks
              .map(
                (item) =>
                  `<label class="dropdown-item-custom"><input type="checkbox" name="social_link_ids[]" value="${escapeHtml(item._id)}" data-name="${escapeHtml(item.name)}" class="action-link-checkbox"><div class="link-info"><div class="platform-name">${escapeHtml(item.name)}</div><div class="platform-url">${escapeHtml(item.url)}</div></div></label>`,
              )
              .join("")
          : '<div class="p-3 text-muted">Select saved links in Social Links first.</div>';
      const typeChoices = find("#businessTypeContent");
      if (typeChoices)
        typeChoices.innerHTML = types.length
          ? types
              .map(
                (item) =>
                  `<div class="dropdown-item-custom business-type-item" data-id="${escapeHtml(item._id)}" data-name="${escapeHtml(item.name)}">${escapeHtml(item.name)}</div>`,
              )
              .join("")
          : '<div class="p-3 text-muted">No business types yet.</div>';
      applySavedSettings(settings);
    };
    form.addEventListener(
      "submit",
      async (event) => {
        event.preventDefault();
        event.stopImmediatePropagation();
        const selected = [
          ...document.querySelectorAll(".action-link-checkbox:checked"),
        ].map((box) => box.value);
        const businessType = find("#businessTypeText")?.dataset.value || "";
        const button = find("#saveBusinessBtn");
        if (button) {
          button.disabled = true;
          button.innerHTML =
            '<i class="fas fa-spinner fa-spin me-2"></i>Saving...';
        }
        try {
          await request("/business-link-settings", {
            method: "PUT",
            body: JSON.stringify({ businessType, actionLinkIds: selected }),
          });
          notify("Business link settings saved.");
        } catch (error) {
          notify(error.message, true);
        } finally {
          if (button) {
            button.disabled = false;
            button.innerHTML =
              '<i class="fas fa-save me-2"></i>Save Business Details';
          }
        }
      },
      true,
    );
    document.addEventListener("click", async (event) => {
      const type = event.target.closest(".business-type-item");
      if (type) {
        const text = find("#businessTypeText");
        if (text) {
          text.textContent = type.dataset.name;
          text.dataset.value = type.dataset.name;
        }
        find("#business_type_id").value = type.dataset.id;
        find("#businessTypeContent")?.classList.remove("active");
        request(
          "/business-link-settings?businessType=" +
            encodeURIComponent(type.dataset.name),
        )
          .then((data) => applySavedSettings(data.data || null))
          .catch((error) => notify(error.message, true));
      }
      const remove = event.target.closest(".remove-link-tag");
      if (remove) {
        const box = document.querySelector(
          `.action-link-checkbox[value="${CSS.escape(remove.dataset.linkId)}"]`,
        );
        if (box) {
          box.checked = false;
          updateSelected();
        }
      }
    });
    document.addEventListener("change", (event) => {
      if (event.target.matches(".action-link-checkbox")) updateSelected();
    });
    find("#businessTypeForm")?.addEventListener(
      "submit",
      async (event) => {
        event.preventDefault();
        event.stopImmediatePropagation();
        const name = String(find("#type_name")?.value || "").trim();
        if (!name) {
          notify("Enter a business type.", true);
          return;
        }
        try {
          await request("/business-types", {
            method: "POST",
            body: JSON.stringify({ name }),
          });
          notify("Business type added.");
          bootstrap.Modal.getOrCreateInstance(
            find("#addBusinessTypeModal"),
          ).hide();
          find("#businessTypeForm").reset();
          await load();
        } catch (error) {
          notify(error.message, true);
        }
      },
      true,
    );
    await load();
  }

  document.addEventListener("DOMContentLoaded", () =>
    setTimeout(() => {
      const page = path.includes("/master/master-list")
        ? sequences
        : path.includes("/leads/index")
          ? leads
          : path.includes("/social/link-document")
            ? connectBusinessLinkSettings
            : path.includes("/social/index")
              ? () =>
                  Promise.all([
                    connectSocialQuickLinks(),
                    connectBusinessCard(),
                  ])
              : path.includes("/reports/campaign")
                ? tracking
                : null;
      Promise.resolve(page?.()).catch((error) => notify(error.message, true));
    }, 0),
  );
})();
