(function () {
  "use strict";

  const isLocal = ["localhost", "127.0.0.1"].includes(window.location.hostname);
  const apiBase = isLocal
    ? "http://localhost:3000/api"
    : (localStorage.getItem("highCustomApiBase") || "https://high-custom-app.onrender.com/api");
  const token = localStorage.getItem("highCustomAdminToken");

  function request(path, options = {}) {
    const headers = {
      Accept: "application/json",
      Authorization: `Bearer ${token}`,
      ...(options.headers || {}),
    };
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

  $.ajaxPrefilter(function (options, originalOptions) {
    if (originalOptions.url !== "#") return;
    if (!originalOptions.data || originalOptions.data.draw === undefined)
      return;
    options.url = `${apiBase}/admin/tracking-report`;
    options.type = "GET";
    options.headers = {
      ...(options.headers || {}),
      Accept: "application/json",
      Authorization: `Bearer ${token}`,
    };
    options.data = { ...originalOptions.data, draw: originalOptions.data.draw };
    delete options.data._token;
    delete options.data._;
  });

  document.addEventListener("DOMContentLoaded", function () {
    const table = document.getElementById("UserSequenceTable");
    if (!table || !window.jQuery) return;
    request("/admin/users")
      .then((payload) => {
        const users = payload.data || [];
        const nameFilter = document.getElementById("user_name_filter");
        const emailFilter = document.getElementById("user_email_filter");
        users.forEach((user) => {
          const name =
            `${user.firstName || ""} ${user.lastName || ""}`.trim() ||
            user.email;
          // Use the real id as the option value. A display name is not unique
          // and a full name cannot reliably be matched against first/last name
          // fields on the server.
          if (nameFilter) nameFilter.add(new Option(name, user._id));
          if (emailFilter && user.email)
            emailFilter.add(new Option(user.email, user.email));
        });
      })
      .catch((error) =>
        console.error("Unable to load tracking filters:", error),
      );
    document.querySelectorAll(".column-search-input").forEach((input) => {
      input.addEventListener("input", function () {
        const column = Number(this.dataset.column);
        if (column === 1)
          document.querySelector("#user_name_filter").value = "";
      });
    });
  });
})();
