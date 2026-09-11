(function () {
  "use strict";

  const apiBase =
    localStorage.getItem("highCustomApiBase") ||
    (["localhost", "127.0.0.1"].includes(window.location.hostname)
      ? "http://localhost:3000/api"
      : "https://high-custom-app.onrender.com/api");
  const token = localStorage.getItem("highCustomAdminToken");

  function request(path, options = {}) {
    const headers = {
      Accept: "application/json",
      Authorization: `Bearer ${token}`,
      ...(options.headers || {}),
    };
    if (options.body && !(options.body instanceof FormData))
      headers["Content-Type"] = "application/json";
    return fetch(`${apiBase}${path}`, { ...options, headers }).then(
      async (response) => {
        const payload = await response.json().catch(() => ({}));
        if (response.status === 401 || response.status === 403) {
          localStorage.removeItem("highCustomAdminToken");
          window.location.replace("../admin-login.html?reason=access");
          throw new Error("Your admin session has expired.");
        }
        if (!response.ok || payload.success === false)
          throw new Error(payload.message || "Request failed.");
        return payload;
      },
    );
  }

  const escapeHtml = (value) =>
    String(value || "").replace(
      /[&<>"']/g,
      (character) =>
        ({
          "&": "&amp;",
          "<": "&lt;",
          ">": "&gt;",
          '"': "&quot;",
          "'": "&#039;",
        })[character],
    );
  const selectedIds = () =>
    [...document.querySelectorAll(".action-link-checkbox:checked")].map(
      (checkbox) => checkbox.value,
    );

  function refreshSelectedLinks() {
    const checked = [
      ...document.querySelectorAll(".action-link-checkbox:checked"),
    ];
    const container = document.getElementById("selectedLinksList");
    const count = document.getElementById("selectedCount");
    if (count)
      count.textContent = checked.length
        ? `${checked.length} Link(s) Selected`
        : "Select Links";
    if (!container) return;
    container.innerHTML = checked.length
      ? checked
          .map(
            (checkbox) =>
              `<span class="badge badge-light d-flex align-items-center p-2" style="background:#404e4ede;font-size:.9rem;border-radius:20px"><span>${escapeHtml(checkbox.dataset.name)}</span><i class="fas fa-times ms-2 text-danger remove-link-tag" data-link-id="${checkbox.value}" style="cursor:pointer"></i></span>`,
          )
          .join("")
      : '<span id="noSelectedMsg" class="text-muted">No links selected</span>';
  }

  function renderLinks(links, selected = []) {
    const selectedSet = new Set((selected || []).map(String));
    const content = document.getElementById("dropdownContent");
    if (!content) return;
    content.innerHTML = (links || [])
      .map((link) => {
        const id = String(link._id || link.id);
        const name = link.name || link.platform || "Link";
        return `<label class="dropdown-item-custom"><input type="checkbox" name="social_link_ids[]" value="${id}" class="action-link-checkbox" data-name="${escapeHtml(name)}" ${selectedSet.has(id) ? "checked" : ""}><div class="link-info"><div class="platform-name">${escapeHtml(name)}</div><div class="platform-url">${escapeHtml(link.url)}</div></div></label>`;
      })
      .join("");
    content
      .querySelectorAll(".action-link-checkbox")
      .forEach((checkbox) =>
        checkbox.addEventListener("change", refreshSelectedLinks),
      );
    refreshSelectedLinks();
  }

  function renderBusinessTypes(items, selectedName) {
    const content = document.getElementById("businessTypeContent");
    if (!content) return;
    content.innerHTML = (items || [])
      .map(
        (item) =>
          `<div class="dropdown-item-custom business-type-item" data-id="${item._id}" data-name="${escapeHtml(item.name)}">${escapeHtml(item.name)}</div>`,
      )
      .join("");
    const selected = (items || []).find((item) => item.name === selectedName);
    if (selected) {
      document.getElementById("business_type_id").value = selected._id;
      document.getElementById("business_type_id").dataset.name = selected.name;
      document.getElementById("businessTypeText").textContent = selected.name;
    }
  }

  function loadSettings(businessType) {
    const query = businessType
      ? `?businessType=${encodeURIComponent(businessType)}`
      : "";
    return request(`/business-link-settings${query}`).then(({ data }) => {
      if (!data) return;
      const whatsapp = document.querySelector('[name="whatsapp_link"]');
      if (whatsapp) whatsapp.value = data.whatsappUrl || "";
      const preview = document.getElementById("imagePreview");
      if (preview) preview.src = data.logoUrl || "../images/user-icon.jpg";
      document.querySelectorAll(".action-link-checkbox").forEach((checkbox) => {
        checkbox.checked = (data.actionLinkIds || [])
          .map(String)
          .includes(checkbox.value);
      });
      refreshSelectedLinks();
    });
  }

  document.addEventListener("DOMContentLoaded", () => {
    let links = [];
    Promise.all([request("/social-links"), request("/business-types")])
      .then(([linkPayload, typePayload]) => {
        links = linkPayload.data || [];
        renderLinks(links);
        renderBusinessTypes(typePayload.data || []);
        return loadSettings("");
      })
      .catch((error) =>
        window.toastr ? toastr.error(error.message) : console.error(error),
      );

    document.addEventListener("click", (event) => {
      const type = event.target.closest(".business-type-item");
      const remove = event.target.closest(".remove-link-tag");
      if (type) {
        document.getElementById("business_type_id").dataset.name =
          type.dataset.name;
        document.getElementById("business_type_id").value = type.dataset.id;
        document.getElementById("businessTypeText").textContent =
          type.dataset.name;
        loadSettings(type.dataset.name).catch((error) =>
          toastr.error(error.message),
        );
      }
      if (remove) {
        const checkbox = document.querySelector(
          `.action-link-checkbox[value="${remove.dataset.linkId}"]`,
        );
        if (checkbox) {
          checkbox.checked = false;
          refreshSelectedLinks();
        }
      }
    });

    document.addEventListener(
      "submit",
      (event) => {
        if (event.target.id === "businessForm") {
          event.preventDefault();
          event.stopImmediatePropagation();
          const button = document.getElementById("saveBusinessBtn");
          const businessType =
            document.getElementById("business_type_id")?.dataset.name || "";
          button.disabled = true;
          request("/business-link-settings", {
            method: "PUT",
            body: JSON.stringify({
              businessType,
              actionLinkIds: selectedIds(),
            }),
          })
            .then((payload) => {
              button.disabled = false;
              toastr.success(payload.message || "Business details saved.");
              loadSettings(businessType);
            })
            .catch((error) => {
              button.disabled = false;
              toastr.error(error.message);
            });
        }
        if (event.target.id === "businessTypeForm") {
          event.preventDefault();
          event.stopImmediatePropagation();
          const input = document.getElementById("type_name");
          request("/business-types", {
            method: "POST",
            body: JSON.stringify({ name: input.value }),
          })
            .then((payload) => {
              input.value = "";
              toastr.success(payload.message || "Business type added.");
              return request("/business-types");
            })
            .then((payload) => renderBusinessTypes(payload.data || []))
            .catch((error) => toastr.error(error.message));
        }
      },
      true,
    );
  });
})();
