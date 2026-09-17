(() => {
  "use strict";
  // Interested Leads has its own dedicated layout and data loader. Do not
  // initialize the regular Master Leads page underneath it.
  if (new URLSearchParams(location.search).get("status") === "interested")
    return;
  const local = ["localhost", "127.0.0.1"].includes(location.hostname);
  const api = local
    ? "http://localhost:3000/api"
    : localStorage.getItem("highCustomApiBase") ||
      "https://high-custom-app.onrender.com/api";
  const token = localStorage.getItem("highCustomAdminToken");
  const esc = (v) =>
    String(v ?? "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  function note(message, bad = false) {
    // Keep feedback visible even when the external toastr stylesheet/script is
    // unavailable. The notice is deliberately independent of a page reload.
    document.querySelector(".mlp-live-notice")?.remove();
    const notice = document.createElement("div");
    notice.className = "mlp-live-notice";
    notice.setAttribute("role", "status");
    notice.textContent = message;
    Object.assign(notice.style, {
      position: "fixed",
      top: "98px",
      right: "24px",
      zIndex: "3000",
      maxWidth: "360px",
      padding: "13px 18px",
      borderRadius: "10px",
      color: "#fff",
      background: bad ? "#b42318" : "#157347",
      boxShadow: "0 12px 28px rgba(15, 23, 42, .2)",
      fontWeight: "700",
      transition: "opacity .2s ease, transform .2s ease",
    });
    document.body.append(notice);
    setTimeout(() => {
      notice.style.opacity = "0";
      notice.style.transform = "translateY(-8px)";
      setTimeout(() => notice.remove(), 220);
    }, 3200);
  }
  const date = (v) =>
    v
      ? new Intl.DateTimeFormat("en-GB", {
          day: "numeric",
          month: "short",
          year: "numeric",
          hour: "2-digit",
          minute: "2-digit",
          hour12: true,
        })
          .format(new Date(v))
          .replace(",", "")
      : "—";
  const today = new Intl.DateTimeFormat("en-GB", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(new Date());
  let leads = [],
    page = 1,
    perPage = 10;
  async function request(path, options = {}) {
    const form = options.body instanceof FormData;
    const response = await fetch(api + path, {
      ...options,
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token}`,
        ...(!form && options.body
          ? { "Content-Type": "application/json" }
          : {}),
        ...(options.headers || {}),
      },
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok || data.success === false)
      throw new Error(data.message || "Request failed.");
    return data;
  }
  function layout() {
    return `<section class="mlp"><div class="mlp-top"><div class="mlp-heading"><div class="mlp-crumb">Master <i class="fa-solid fa-chevron-right"></i> Leads</div><h1>Leads</h1><p>View and manage leads across the platform.</p></div><div class="mlp-top-actions"><div class="mlp-date"><i class="fa-regular fa-calendar-days"></i><span><small>Today</small><strong>${today}</strong></span><i class="fa-solid fa-chevron-down"></i></div><button class="mlp-btn mlp-primary" data-new><i class="fa-solid fa-plus"></i>New Lead Entry</button></div></div><section class="mlp-entry" id="mlpEntry"><header class="mlp-entryhead"><span><i class="fa-solid fa-user-plus"></i></span><span><h2>New Lead Entry</h2><p>Add a new lead to your system.</p></span></header><form class="mlp-form" id="mlpForm"><div class="mlp-field"><label>Email ID *</label><span class="mlp-wrap"><i class="fa-regular fa-envelope"></i><input name="email" type="email" placeholder="Enter email address" required></span></div><div class="mlp-field"><label>First Name *</label><span class="mlp-wrap"><i class="fa-regular fa-user"></i><input name="firstName" placeholder="Enter first name" required></span></div><div class="mlp-field"><label>Last Name *</label><span class="mlp-wrap"><i class="fa-regular fa-user"></i><input name="lastName" placeholder="Enter last name" required></span></div><div class="mlp-field"><label>Company Name *</label><span class="mlp-wrap"><i class="fa-regular fa-building"></i><input name="company" placeholder="Enter company name" required></span></div><div class="mlp-field"><label>Business Type</label><span class="mlp-wrap"><i class="fa-solid fa-tag"></i><select name="businessType" id="mlpType" required><option value="">Select business type</option></select></span></div><button class="mlp-btn mlp-add" type="submit"><i class="fa-solid fa-plus"></i>Add Lead</button></form></section><div class="mlp-tools"><div class="mlp-tools-left"><button class="mlp-btn mlp-primary" data-export><i class="fa-solid fa-download"></i>Download Excel File</button><label class="mlp-btn"><i class="fa-solid fa-upload"></i>Excel Upload<input type="file" id="mlpImport" accept=".xlsx,.xls" hidden></label><div class="mlp-today"><i class="fa-regular fa-calendar-days"></i>Today Added : <span id="mlpToday">0</span></div></div><div class="mlp-tools-right"><div class="mlp-search"><i class="fa-solid fa-magnifying-glass"></i><input id="mlpSearch" placeholder="Search by email, name, company..."></div><button class="mlp-btn" data-filter><i class="fa-solid fa-filter"></i>Filter</button><button class="mlp-btn" data-reset><i class="fa-solid fa-rotate-right"></i>Reset</button></div></div><section class="mlp-tablecard"><div class="mlp-scroll"><table class="mlp-table"><thead><tr><th>#</th><th>Email</th><th>Name</th><th>Company</th><th>Business Type</th><th>Channel</th><th>Tracking</th><th>Added</th><th>Actions</th></tr></thead><tbody id="mlpRows"></tbody></table></div><footer class="mlp-footer"><span id="mlpInfo">Loading leads…</span><span class="mlp-pages" id="mlpPages"></span></footer></section></section>`;
  }
  const state = (l) => {
    const text = String(
      l.trackingStatus || (l.tracking === false ? "Skip" : "Pending"),
    );
    return `<span class="mlp-status mlp-status--${esc(text.toLowerCase().replace(/\s+/g, "-"))}">${esc(text)}</span>`;
  };
  function shown() {
    const q = document.querySelector("#mlpSearch").value.trim().toLowerCase();
    return leads.filter(
      (l) =>
        !q ||
        [l.email, l.firstName, l.lastName, l.company, l.businessType]
          .join(" ")
          .toLowerCase()
          .includes(q),
    );
  }
  function render() {
    const list = shown(),
      start = (page - 1) * perPage,
      rows = list.slice(start, start + perPage),
      body = document.querySelector("#mlpRows");
    body.innerHTML = rows.length
      ? rows
          .map(
            (l, i) =>
              `<tr><td>${start + i + 1}</td><td>${esc(l.email || "—")}</td><td>${esc([l.firstName, l.lastName].filter(Boolean).join(" ") || "—")}</td><td>${esc(l.company || "—")}</td><td><span class="mlp-badge">${esc(l.businessType || "—")}</span></td><td>${esc(l.type || "Email")}</td><td>${state(l)}</td><td>${date(l.addedDate || l.createdAt)}</td><td><div class="mlp-actions"><button class="mlp-icon" data-view="${esc(l._id)}" title="View"><i class="fa-solid fa-eye"></i></button><button class="mlp-icon edit" data-edit="${esc(l._id)}" title="Edit"><i class="fa-solid fa-pen"></i></button><button class="mlp-icon delete" data-delete="${esc(l._id)}" title="Delete"><i class="fa-solid fa-trash"></i></button></div></td></tr>`,
          )
          .join("")
      : `<tr><td class="mlp-empty" colspan="9">No leads found.</td></tr>`;
    document.querySelector("#mlpInfo").textContent = list.length
      ? `Showing ${start + 1} to ${Math.min(start + perPage, list.length)} of ${list.length} leads`
      : "Showing 0 leads";
    const total = Math.max(1, Math.ceil(list.length / perPage));
    document.querySelector("#mlpPages").innerHTML =
      `<button class="mlp-page" data-page="${page - 1}" ${page === 1 ? "disabled" : ""}>‹</button>${Array.from({ length: Math.min(total, 5) }, (_, i) => `<button class="mlp-page ${page === i + 1 ? "active" : ""}" data-page="${i + 1}">${i + 1}</button>`).join("")}<button class="mlp-page" data-page="${page + 1}" ${page === total ? "disabled" : ""}>›</button>`;
  }
  function refreshLeadSummary() {
    document.querySelector("#mlpToday").textContent = leads.filter(
      (l) =>
        new Date(l.addedDate || l.createdAt).toDateString() ===
        new Date().toDateString(),
    ).length;
  }
  async function load() {
    leads = (await request("/leads/get-leads")).leads || [];
    refreshLeadSummary();
    render();
  }
  function popup(lead, editable) {
    const fields = [
      ["Email", "email"],
      ["First name", "firstName"],
      ["Last name", "lastName"],
      ["Company", "company"],
      ["Business type", "businessType"],
    ];
    const overlay = document.createElement("div");
    overlay.className = "modal-backdrop show";
    overlay.style.zIndex = 2200;
    overlay.innerHTML = `<div class="modal d-block" tabindex="-1"><div class="modal-dialog modal-dialog-centered"><form class="modal-content"><div class="modal-header"><h5 class="modal-title">${editable ? "Edit Lead" : "Lead Details"}</h5><button type="button" class="btn-close" data-close></button></div><div class="modal-body"><div class="row g-3">${fields.map(([title, key]) => `<label class="col-6 form-label">${title}<input class="form-control mt-1" name="${key}" value="${esc(lead[key] || "")}" ${editable ? "" : "readonly"}></label>`).join("")}</div></div><div class="modal-footer"><button class="btn btn-light" type="button" data-close>Close</button>${editable ? '<button class="btn btn-primary" type="submit">Save Changes</button>' : ""}</div></form></div></div>`;
    document.body.append(overlay);
    overlay.addEventListener("click", async (e) => {
      if (e.target === overlay || e.target.closest("[data-close]")) {
        overlay.remove();
        return;
      }
      if (editable && e.target.closest("form")) {
        e.preventDefault();
        try {
          await request("/leads/update-lead/" + lead._id, {
            method: "PUT",
            body: JSON.stringify(
              Object.fromEntries(new FormData(e.currentTarget)),
            ),
          });
          overlay.remove();
          note("Lead updated successfully.");
          await load();
        } catch (err) {
          note(err.message, true);
        }
      }
    });
  }
  function bind() {
    const root = document.querySelector(".mlp");
    root.addEventListener("click", async (e) => {
      const b = e.target.closest("button");
      if (!b) return;
      if (b.dataset.new !== undefined) {
        document
          .querySelector("#mlpEntry")
          .scrollIntoView({ behavior: "smooth", block: "center" });
        return;
      }
      if (b.dataset.reset !== undefined) {
        document.querySelector("#mlpSearch").value = "";
        page = 1;
        render();
        return;
      }
      if (b.dataset.filter !== undefined) {
        document.querySelector("#mlpSearch").focus();
        return;
      }
      if (b.dataset.page) {
        page = Number(b.dataset.page);
        render();
        return;
      }
      if (b.dataset.export !== undefined) {
        try {
          const r = await fetch(api + "/leads/export-excel", {
            headers: { Authorization: `Bearer ${token}` },
          });
          if (!r.ok) throw new Error("Unable to export leads.");
          const a = document.createElement("a");
          a.href = URL.createObjectURL(await r.blob());
          a.download = "leads.xlsx";
          a.click();
        } catch (err) {
          note(err.message, true);
        }
        return;
      }
      const l = leads.find(
        (x) =>
          String(x._id) ===
          String(b.dataset.view || b.dataset.edit || b.dataset.delete),
      );
      if (!l) return;
      if (b.dataset.view) popup(l, false);
      if (b.dataset.edit) popup(l, true);
      if (b.dataset.delete && confirm(`Delete ${l.email}?`)) {
        try {
          await request("/leads/delete-lead/" + l._id, { method: "DELETE" });
          note("Lead deleted.");
          await load();
        } catch (err) {
          note(err.message, true);
        }
      }
    });
    document.querySelector("#mlpSearch").addEventListener("input", () => {
      page = 1;
      render();
    });
    document.querySelector("#mlpForm").addEventListener("submit", async (e) => {
      e.preventDefault();
      // Event.currentTarget is cleared by the browser after an await. Keep the
      // form reference before starting the request so a successful create can
      // never be reported as an error while the lead was actually saved.
      const form = e.currentTarget;
      const data = Object.fromEntries(new FormData(form));
      data.type = "Email";
      data.tracking = true;
      const submitButton = form.querySelector('[type="submit"]');
      const originalButton = submitButton.innerHTML;
      submitButton.disabled = true;
      submitButton.innerHTML =
        '<i class="fa-solid fa-spinner fa-spin"></i> Adding…';
      try {
        const result = await request("/leads/create-lead", {
          method: "POST",
          body: JSON.stringify(data),
        });
        form.reset();

        // Show the newly-created lead immediately. The background reload then
        // synchronizes statuses/ordering without making the user refresh.
        if (result.lead) {
          leads = [
            {
              ...result.lead,
              createdAt: result.lead.createdAt || new Date().toISOString(),
            },
            ...leads.filter(
              (lead) => String(lead._id) !== String(result.lead._id),
            ),
          ];
          page = 1;
          refreshLeadSummary();
          render();
        }
        note("Lead added successfully.");
        load().catch(() => {});
      } catch (err) {
        note(err.message, true);
      } finally {
        submitButton.disabled = false;
        submitButton.innerHTML = originalButton;
      }
    });
    document
      .querySelector("#mlpImport")
      .addEventListener("change", async (e) => {
        if (!e.target.files[0]) return;
        const data = new FormData();
        data.append("file", e.target.files[0]);
        try {
          const r = await request("/leads/import-excel", {
            method: "POST",
            body: data,
          });
          note(r.message || "Leads imported successfully.");
          await load();
        } catch (err) {
          note(err.message, true);
        }
        e.target.value = "";
      });
  }
  document.addEventListener("DOMContentLoaded", () =>
    setTimeout(async () => {
      if (!token) return;
      const main = document.querySelector("#mainContent");
      if (!main) return;
      main.innerHTML = layout();
      bind();
      try {
        const [typeData] = await Promise.all([
          request("/business-types"),
          load(),
        ]);
        document.querySelector("#mlpType").innerHTML =
          '<option value="">Select business type</option>' +
          (typeData.data || [])
            .map(
              (t) => `<option value="${esc(t.name)}">${esc(t.name)}</option>`,
            )
            .join("");
      } catch (err) {
        note(err.message, true);
      }
    }, 25),
  );
})();
