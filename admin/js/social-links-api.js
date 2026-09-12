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
    if (options.body && typeof options.body !== "string")
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

  const notify = (message, error = false) =>
    window.toastr
      ? error
        ? toastr.error(message)
        : toastr.success(message)
      : console.error(message);
  let links = [];

  function refreshLinks() {
    return request("/social-links").then((payload) => {
      links = payload.data || [];
      document.querySelectorAll(".qr-platform-checkbox").forEach((checkbox) => {
        const input = document.getElementById(checkbox.dataset.input);
        if (input) {
          const existing = links.find(
            (link) =>
              link.platform === checkbox.dataset.platform ||
              link.name === checkbox.dataset.platform,
          );
          if (existing) input.value = existing.url || "";
          checkbox.checked = Boolean(existing?.selected);
        }
      });
      return links;
    });
  }

  window.refreshAllQRs = function () {
    return request("/social-links/qr")
      .then((payload) => {
        if (typeof window.renderMultipleQRs === "function")
          window.renderMultipleQRs(payload.data || [], "#multipleQrContainer");
        return payload.data || [];
      })
      .catch((error) => {
        notify(error.message, true);
        throw error;
      });
  };

  window.saveQuickLink = function (platformKey, platformName, button) {
    const input = document.getElementById(platformKey);
    const url = input?.value.trim() || "";
    if (!url) return notify("Enter a URL first.", true);
    button.disabled = true;
    request("/social-links", {
      method: "POST",
      body: JSON.stringify({ name: platformName, platform: platformName, url }),
    })
      .then(() => {
        notify(`${platformName} link saved.`);
        return refreshLinks();
      })
      .catch((error) => notify(error.message, true))
      .finally(() => {
        button.disabled = false;
      });
  };

  window.addMultipleQR = function () {
    const selected = [
      ...document.querySelectorAll(".qr-platform-checkbox:checked"),
    ]
      .map(
        (checkbox) =>
          links.find(
            (link) =>
              link.platform === checkbox.dataset.platform ||
              link.name === checkbox.dataset.platform,
          )?._id,
      )
      .filter(Boolean);
    if (!selected.length)
      return notify("Save and select at least one link first.", true);
    request("/social-links/generate-qr", {
      method: "POST",
      body: JSON.stringify({ linkIds: selected }),
    })
      .then(() => {
        notify("QR code generated.");
        return window.refreshAllQRs();
      })
      .catch((error) => notify(error.message, true));
  };

  window.deleteQR = function (qrId) {
    if (qrId === "all-links")
      return notify("The All Links QR code cannot be deleted.", true);
    if (!window.confirm("Are you sure you want to delete this QR code?\n\nThe saved Social Link will remain.")) return;
    request(`/social-links/${encodeURIComponent(qrId)}/qr`, {
      method: "DELETE",
    })
      .then(() => {
        notify("QR code deleted.");
        return window.refreshAllQRs();
      })
      .catch((error) => notify(error.message, true));
  };

  document.addEventListener("DOMContentLoaded", () => {
    refreshLinks().catch((error) => notify(error.message, true));
  });
})();
