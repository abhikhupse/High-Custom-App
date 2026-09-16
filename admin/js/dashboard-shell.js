(() => {
  "use strict";

  // Dashboard-only content enhancement. Navigation and header are rendered
  // exclusively by static-navigation.js on every Admin route.
  document.addEventListener("DOMContentLoaded", () => {
    const headerFilters = document.getElementById("dashboardHeaderFilters");
    const userFilter = document.querySelector(".user-filter-wrap");
    const dateFilter = document.querySelector(".date-filter-wrap");
    if (headerFilters) {
      if (userFilter) headerFilters.append(userFilter);
      if (dateFilter) headerFilters.append(dateFilter);
    }

    document.querySelectorAll(".dashboard-card .card-info").forEach((info) => {
      if (info.querySelector(".dashboard-card-leading-icon")) return;
      const icon = info.querySelector(".dashboard-icon")?.cloneNode(true);
      if (!icon) return;
      icon.classList.add("dashboard-card-leading-icon");
      info.insertBefore(icon, info.firstElementChild);
    });
  });
})();
