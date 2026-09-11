(function () {
  "use strict";

  const apiBase =
    localStorage.getItem("highCustomApiBase") ||
    (["localhost", "127.0.0.1"].includes(window.location.hostname)
      ? "http://localhost:3000/api"
      : "https://high-custom-app.onrender.com/api");
  const token = localStorage.getItem("highCustomAdminToken");

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
          if (nameFilter) nameFilter.add(new Option(name, name));
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
