(function () {
  "use strict";
  const sidebar = document.getElementById("sidebar");
  const nav = sidebar?.querySelector(".nav-menu");
  if (!nav) return;
  const route = (path) => new URL(path, window.location.href).pathname;
  const isActive = (path) => location.pathname.toLowerCase() === route(path).toLowerCase() ? " active" : "";
  const item = (label, icon, path) => `<li class="nav-item"><a class="nav-link${isActive(path)}" href="${path}"><i class="fas ${icon}"></i><span class="menu-text">${label}</span></a></li>`;
  const group = (id, label, icon, links) => `<li class="nav-item"><button type="button" class="nav-link w-100 border-0 bg-transparent text-start" data-dashboard-submenu="${id}" aria-expanded="false"><i class="fas ${icon}"></i><span class="menu-text">${label}</span><i class="fas fa-chevron-down arrow"></i></button><ul class="sub-menu" id="${id}">${links}</ul></li>`;
  nav.innerHTML = [
    item("Dashboard", "fa-house", "dashboard.html"),
    group("premium-admin-menu", "Admin", "fa-user-shield", [
      item("Users", "fa-user", "users/index.html"), item("Sequences", "fa-layer-group", "master/userMasterList.html"), item("Leads", "fa-users", "Leads/total-leads.html?scope=admin"), item("Interested Leads", "fa-bullseye", "Leads/total-leads.html?scope=admin&status=interested"), item("All Tracking Report", "fa-chart-column", "master/UserSequenceTable.html")
    ].join("")),
    group("premium-master-menu", "Master", "fa-database", [
      item("Social Link", "fa-share-nodes", "social/index.html"), item("Link", "fa-link", "social/link-document.html"), item("Leads", "fa-users", "Leads/index.html"), item("Sequences", "fa-layer-group", "master/master-list.html"), item("Tracking Report", "fa-chart-line", "reports/campaign.html"), item("Interested Leads", "fa-bullseye", "Leads/index.html?status=interested")
    ].join("")),
  ].join("");
  nav.querySelectorAll("[data-dashboard-submenu]").forEach((button) => {
    const menu = document.getElementById(button.dataset.dashboardSubmenu);
    // The dashboard reference keeps both navigation groups available at a glance.
    const hasActive = Boolean(menu?.querySelector(".active"));
    if (menu) menu.classList.add("open");
    button.classList.toggle("active-indicator", hasActive);
    button.setAttribute("aria-expanded", "true");
    button.querySelector(".arrow")?.classList.add("open");
    button.addEventListener("click", () => { const open = menu.classList.toggle("open"); button.classList.toggle("active-indicator", open); button.setAttribute("aria-expanded", String(open)); button.querySelector(".arrow")?.classList.toggle("open", open); });
  });
  const userFilter = document.querySelector(".user-filter-wrap");
  const dateFilter = document.querySelector(".date-filter-wrap");
  const headerFilter = document.getElementById("dashboardHeaderFilters");
  if (headerFilter) {
    if (userFilter) headerFilter.append(userFilter);
    if (dateFilter) headerFilter.append(dateFilter);
  }

  // Each reference metric card has a large leading icon and a smaller accent icon.
  // Clone the existing real card icon instead of introducing a separate icon/data map.
  document.querySelectorAll(".dashboard-card .card-info").forEach((info) => {
    if (info.querySelector(".dashboard-card-leading-icon")) return;
    const existing = info.querySelector(".dashboard-icon");
    const copy = existing?.cloneNode(true);
    if (!copy) return;
    copy.classList.add("dashboard-card-leading-icon");
    info.insertBefore(copy, info.firstElementChild);
  });

  // static-navigation.js now applies the active state after legacy page
  // callbacks complete. A second repeating callback here caused Dashboard to
  // flash between its active and inactive styles.
})();
