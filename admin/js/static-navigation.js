(function () {
  "use strict";

  if (!document.getElementById("adminMobileResponsiveCss")) {
    const responsiveCss = document.createElement("link");
    responsiveCss.id = "adminMobileResponsiveCss";
    responsiveCss.rel = "stylesheet";
    responsiveCss.href = new URL(
      "css/admin-mobile-responsive.css",
      getAdminRoot(),
    ).href;
    document.head.append(responsiveCss);
  }

  function getAdminRoot() {
    const path = window.location.pathname;
    const adminMarker = "/admin/";
    const markerIndex = path.toLowerCase().indexOf(adminMarker);
    return `${window.location.origin}${markerIndex >= 0 ? path.slice(0, markerIndex + adminMarker.length) : "/"}`;
  }

  const adminRoot = getAdminRoot();
  const routes = {
    Dashboard: "dashboard.html",
    Master: "master/master-list.html",
    Sequence: "master/master-list.html",
    Link: "social/link-document.html",
    Leads: "Leads/index.html",
    "Social Links": "social/index.html",
    "Tracking Report": "reports/campaign.html",
    "Users Master": "master/userMasterList.html",
    "Users Rights": "users/index.html",
    "All Tracking": "master/UserSequenceTable.html",
  };

  const normalize = (value) => value.replace(/\s+/g, " ").trim();
  const routeUrl = (route) =>
    new URL(route, adminRoot).pathname.replace(/\/$/, "") || "/";
  const currentPath = window.location.pathname.replace(/\/$/, "") || "/";

  // Keep Admin navigation in the same flow as the User Panel:
  // Admin → Social Links, Link, Sequence, Tracking Report; Leads is standalone.
  const organiseAdminFlow = () => {
    const submenu = document.getElementById("submenu-admin");
    const adminParent = document.getElementById("adminParentLink");
    if (!submenu || !adminParent) return;
    const linkByName = (name) =>
      [...submenu.querySelectorAll(".nav-link")].find(
        (link) => normalize(link.textContent) === name,
      );
    const master = linkByName("Master");
    if (master) {
      master.innerHTML = '<i class="fas fa-envelope"></i> Sequence';
    }
    const sequence = linkByName("Sequence");
    const social = linkByName("Social Links");
    const link = linkByName("Link");
    const tracking = linkByName("Tracking Report");
    const leads = linkByName("Leads");
    [social, link, sequence, tracking]
      .filter(Boolean)
      .forEach((item) => submenu.append(item.closest(".nav-item")));
    if (leads) {
      const leadsItem = leads.closest(".nav-item");
      const adminItem = adminParent.closest(".nav-item");
      leadsItem.setAttribute("role", "none");
      leads.innerHTML =
        '<i class="fas fa-chart-line"></i><span class="menu-text">Leads</span>';
      adminItem.after(leadsItem);
    }
  };
  organiseAdminFlow();

  // On phones, render each table row as a labelled card. Header text becomes
  // the label, including for data that loads dynamically from the backend.
  const prepareMobileTableCards = () => {
    document.querySelectorAll("table").forEach((table) => {
      const headers = [...table.querySelectorAll("thead th")].map(
        (header) => header.textContent.replace(/\s+/g, " ").trim() || "Details",
      );
      if (!headers.length) return;
      table.classList.add("admin-card-table");
      table.querySelectorAll("tbody tr").forEach((row) => {
        [...row.children].forEach((cell, index) => {
          if (cell.tagName === "TD" && !cell.hasAttribute("colspan")) {
            cell.dataset.mobileLabel = headers[index] || "Details";
          }
        });
      });
    });
  };
  prepareMobileTableCards();
  document.addEventListener("DOMContentLoaded", () => {
    prepareMobileTableCards();
    new MutationObserver(prepareMobileTableCards).observe(document.body, {
      childList: true,
      subtree: true,
    });
  });

  document.querySelectorAll(".sidebar .nav-link").forEach((link) => {
    const label = normalize(link.textContent);
    const route = Object.entries(routes).find(([name]) => label === name);

    if (!route) return;

    const targetPath = routeUrl(route[1]);
    link.setAttribute("href", targetPath);

    if (currentPath.toLowerCase() === targetPath.toLowerCase()) {
      link.classList.add("active");
      const submenu = link.closest(".sub-menu");
      if (submenu) {
        submenu.classList.add("open");
        const parent =
          submenu.parentElement.querySelector(":scope > .nav-link");
        parent?.classList.add("active-indicator");
        parent?.setAttribute("aria-expanded", "true");
        parent?.querySelector(".arrow")?.classList.add("open");
      }
    }
  });
})();
