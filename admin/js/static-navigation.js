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

  if (!document.getElementById("adminSharedHeaderCss")) {
    const headerCss = document.createElement("link");
    headerCss.id = "adminSharedHeaderCss";
    headerCss.rel = "stylesheet";
    headerCss.href = new URL(
      "css/admin-shared-header.css",
      getAdminRoot(),
    ).href;
    document.head.append(headerCss);
  }

  if (!document.getElementById("adminSharedSidebarCss")) {
    const sidebarCss = document.createElement("link");
    sidebarCss.id = "adminSharedSidebarCss";
    sidebarCss.rel = "stylesheet";
    // Versioned so every legacy static page receives the current shared shell.
    sidebarCss.href = `${new URL("css/admin-shared-sidebar.css", getAdminRoot()).href}?v=20260912-2`;
    document.head.append(sidebarCss);
  }

  function getAdminRoot() {
    const path = window.location.pathname;
    const adminMarker = "/admin/";
    const markerIndex = path.toLowerCase().indexOf(adminMarker);
    return `${window.location.origin}${markerIndex >= 0 ? path.slice(0, markerIndex + adminMarker.length) : "/"}`;
  }

  const adminRoot = getAdminRoot();

  // A logout control is injected on every Admin workspace page.  Keeping it
  // here means the behaviour is identical for Master, Links, Leads, Social
  // Links and both report pages.
  const signOut = () => {
    localStorage.removeItem("highCustomAdminToken");
    localStorage.removeItem("highCustomAdminUser");
    window.location.replace(new URL("admin-login.html", adminRoot).href);
  };

  const addLogoutControl = () => {
    if (document.getElementById("logoutBtn")) return;
    if (document.getElementById("adminGlobalLogout")) return;
    const header = document.querySelector(".top-navbar, .top-header");
    if (!header) return;
    const button = document.createElement("button");
    button.id = "adminGlobalLogout";
    button.type = "button";
    button.title = "Logout";
    button.setAttribute("aria-label", "Logout from Admin panel");
    button.innerHTML = '<i class="fas fa-sign-out-alt"></i><span>Logout</span>';
    button.style.cssText =
      "border:0;border-radius:9px;background:#dc3545;color:#fff;font:600 13px/1 Arial,sans-serif;padding:9px 13px;display:inline-flex;align-items:center;gap:7px;cursor:pointer;margin-left:10px;white-space:nowrap";
    button.addEventListener("click", signOut);

    const actions =
      header.querySelector(".top-actions, .navbar-actions") || header;
    actions.append(button);
  };
  const upgradeHeader = () => {
    const header = document.querySelector(".top-navbar");
    // The dashboard already owns its premium header and live date controls.
    if (!header || header.classList.contains("premium-topbar")) return;
    const toggle = header.querySelector(".sidebar-toggle");
    const saved = JSON.parse(
      localStorage.getItem("highCustomAdminUser") || "{}",
    );
    const name =
      [saved.firstName, saved.lastName].filter(Boolean).join(" ") ||
      saved.name ||
      "Admin";
    const role = saved.role === "User" ? "Admin" : saved.role || "Admin";
    const initials =
      name
        .split(/\s+/)
        .map((part) => part[0])
        .join("")
        .slice(0, 2)
        .toUpperCase() || "A";

    header.classList.add("universal-dashboard-header");
    header.replaceChildren();

    if (toggle) header.append(toggle);

    const copy = document.createElement("div");
    copy.className = "universal-header-copy";
    copy.innerHTML =
      "<strong>Admin</strong><small>Manage and monitor your High Custom platform</small>";
    header.append(copy);

    const actions = document.createElement("div");
    actions.className = "universal-header-actions";
    actions.innerHTML = `
      <button class="universal-notification" type="button" title="Notifications" aria-label="Notifications">
        <i class="fas fa-bell"></i><span class="universal-notification-badge">3</span>
      </button>
      <div class="dropdown universal-profile-menu">
        <button class="universal-profile-trigger" type="button" data-bs-toggle="dropdown" aria-expanded="false">
          <span class="universal-profile-avatar" data-shared-profile-avatar>${initials}</span>
          <span class="universal-profile-copy"><strong data-shared-profile-name>${name}</strong><small data-shared-profile-role>${role}</small></span>
          <i class="fas fa-chevron-down"></i>
        </button>
        <ul class="dropdown-menu dropdown-menu-end universal-profile-dropdown">
          <li><a class="dropdown-item" href="${new URL("users/profile.html", adminRoot).href}"><i class="fas fa-user"></i> Profile</a></li>
          <li><a class="dropdown-item" href="#"><i class="fas fa-plug"></i> Integrations</a></li>
          <li><a class="dropdown-item" href="#"><i class="fas fa-gear"></i> Settings</a></li>
          <li><hr class="dropdown-divider"></li>
          <li><a class="dropdown-item text-danger" href="#" id="logoutBtn"><i class="fas fa-right-from-bracket"></i> Logout</a></li>
        </ul>
      </div>`;
    header.append(actions);
  };

  // The dashboard already uses /user/profile.  Reuse the exact same source on
  // every other Admin page so the header never falls back to a stale role/name.
  const hydrateHeaderProfile = async () => {
    const token = localStorage.getItem("highCustomAdminToken");
    const profile = document.querySelector(".universal-profile");
    if (!token || !profile) return;

    const isLocal = ["localhost", "127.0.0.1"].includes(
      window.location.hostname,
    );
    const apiBase = isLocal
      ? "http://localhost:3000/api"
      : localStorage.getItem("highCustomApiBase") ||
        "https://high-custom-app.onrender.com/api";
    try {
      const response = await fetch(`${apiBase}/user/profile`, {
        headers: {
          Accept: "application/json",
          Authorization: `Bearer ${token}`,
        },
      });
      const payload = await response.json().catch(() => ({}));
      const user = payload?.user;
      if (!response.ok || !payload?.success || !user) return;

      const name =
        [user.firstName, user.lastName].filter(Boolean).join(" ") ||
        user.email ||
        "Admin";
      const initials =
        name
          .split(/\s+/)
          .filter(Boolean)
          .slice(0, 2)
          .map((part) => part[0])
          .join("")
          .toUpperCase() || "A";
      const nameElement = profile.querySelector("[data-shared-profile-name]");
      const roleElement = profile.querySelector("[data-shared-profile-role]");
      const avatar = profile.querySelector("[data-shared-profile-avatar]");
      if (nameElement) nameElement.textContent = name;
      if (roleElement)
        roleElement.textContent =
          user.role === "User" ? "Admin" : user.role || "Admin";
      if (avatar) {
        avatar.textContent = initials;
        if (user.profileImage) {
          const image = document.createElement("img");
          image.alt = "";
          image.src = /^https?:\/\//i.test(user.profileImage)
            ? user.profileImage
            : `${apiBase.replace(/\/api$/, "")}${user.profileImage}`;
          image.addEventListener("load", () => avatar.replaceChildren(image), {
            once: true,
          });
        }
      }
      localStorage.setItem("highCustomAdminUser", JSON.stringify(user));
    } catch (_) {
      // Keep the cached profile visible if the API is temporarily unavailable.
    }
  };
  upgradeHeader();
  addLogoutControl();
  hydrateHeaderProfile();
  // The two groups intentionally use different routes, even where a screen
  // looks similar. Admin routes load protected company-wide data; Master
  // routes load data derived from the current JWT owner.
  const renderScopedNavigation = () => {
    const nav = document.querySelector(".sidebar .nav-menu");
    if (!nav || nav.dataset.scopedNavigation === "true") return;
    const sidebar = nav.closest(".sidebar");
    const brand = sidebar?.querySelector(".sidebar-brand");
    if (brand) {
      brand.innerHTML = `<a href="${new URL("dashboard.html", adminRoot).pathname}" aria-label="High Custom Admin Panel"><img src="${new URL("images/high-custom-admin-panel-logo.png", adminRoot).href}" alt="High Custom Admin Panel" class="sidebar-logo"></a>`;
    }
    const link = (label, icon, href) => {
      const target = new URL(href, adminRoot);
      return `<li class="nav-item"><a class="nav-link" href="${target.pathname}${target.search}"><i class="fas ${icon}"></i><span class="menu-text">${label}</span></a></li>`;
    };
    const group = (id, label, icon, children) =>
      `<li class="nav-item"><button type="button" class="nav-link w-100 border-0 bg-transparent text-start" data-target="${id}" aria-expanded="true"><i class="fas ${icon}"></i><span class="menu-text">${label}</span><i class="fas fa-chevron-down arrow open"></i></button><ul class="sub-menu open" id="${id}">${children}</ul></li>`;
    nav.innerHTML = [
      link("Dashboard", "fa-house", "dashboard.html"),
      group(
        "submenu-admin",
        "Admin",
        "fa-user-shield",
        [
          link("Users", "fa-user", "users/index.html"),
          link("Sequences", "fa-layer-group", "master/userMasterList.html"),
          link("Leads", "fa-users", "Leads/total-leads.html?scope=admin"),
          link(
            "Interested Leads",
            "fa-bullseye",
            "Leads/total-leads.html?scope=admin&status=interested",
          ),
          link(
            "All Tracking Report",
            "fa-chart-column",
            "master/UserSequenceTable.html",
          ),
        ].join(""),
      ),
      group(
        "submenu-master",
        "Master",
        "fa-database",
        [
          link("Social Link", "fa-share-nodes", "social/index.html"),
          link("Link", "fa-link", "social/link-document.html"),
          link("Leads", "fa-users", "Leads/index.html"),
          link("Sequences", "fa-layer-group", "master/master-list.html"),
          link("Tracking Report", "fa-chart-line", "reports/campaign.html"),
          link(
            "Interested Leads",
            "fa-bullseye",
            "Leads/index.html?status=interested",
          ),
        ].join(""),
      ),
    ].join("");
    nav.dataset.scopedNavigation = "true";
    if (sidebar && !sidebar.querySelector(".sidebar-premium-footer")) {
      const footer = document.createElement("div");
      footer.className = "sidebar-premium-footer";
      footer.innerHTML = "<strong>High Custom</strong><span>Build Relationships</span><span>Create Opportunities</span>";
      nav.insertAdjacentElement("afterend", footer);
    }
    nav.querySelectorAll("[data-target]").forEach((button) => {
      button.addEventListener("click", () => {
        const submenu = document.getElementById(button.dataset.target);
        const open = submenu?.classList.toggle("open");
        button.setAttribute("aria-expanded", String(Boolean(open)));
        button.querySelector(".arrow")?.classList.toggle("open", Boolean(open));
      });
    });
  };
  renderScopedNavigation();

  // Each route above is explicit. Do not remap by menu label: Admin and Master
  // intentionally contain duplicate labels such as Leads and Sequences.

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

  const applyScopedActiveState = () => {
    const current = new URL(window.location.href);
    const links = [...document.querySelectorAll(".sidebar a.nav-link[href]")];
    links.forEach((link) => link.classList.remove("active"));
    document.querySelectorAll(".sidebar [data-target]").forEach((button) =>
      button.classList.remove("active-indicator"),
    );
    const match = links.find((link) => {
      const target = new URL(link.href, window.location.origin);
      return target.pathname.replace(/\/$/, "") === current.pathname.replace(/\/$/, "") && target.search === current.search;
    });
    if (!match) return;
    match.classList.add("active");
    const submenu = match.closest(".sub-menu");
    if (!submenu) return;
    submenu.classList.add("open");
    const parent = submenu.parentElement.querySelector(":scope > .nav-link");
    parent?.classList.add("active-indicator");
    parent?.setAttribute("aria-expanded", "true");
    parent?.querySelector(".arrow")?.classList.add("open");
  };
  applyScopedActiveState();
  // The legacy templates register their old active-menu callback first. Apply
  // the scoped result after it so duplicate routes never highlight wrongly.
  document.addEventListener("DOMContentLoaded", () =>
    window.setTimeout(applyScopedActiveState, 0),
  );

  // A few legacy page templates still run a path-only menu highlighter every
  // second.  Admin Leads and Admin Interested Leads share the same file but
  // have different query strings, so restore the query-aware selection as
  // soon as that older code touches the sidebar instead of showing the wrong
  // gold item between updates.
  document.addEventListener("DOMContentLoaded", () => {
    const nav = document.querySelector(".sidebar .nav-menu");
    if (!nav) return;
    const observer = new MutationObserver(() => {
      const current = new URL(window.location.href);
      const links = [...nav.querySelectorAll("a.nav-link[href]")];
      const expected = links.find((link) => {
        const target = new URL(link.href, window.location.origin);
        return target.pathname.replace(/\/$/, "") === current.pathname.replace(/\/$/, "") && target.search === current.search;
      });
      if (expected && (!expected.classList.contains("active") || links.some((link) => link !== expected && link.classList.contains("active")))) {
        applyScopedActiveState();
      }
    });
    observer.observe(nav, { attributes: true, subtree: true, attributeFilter: ["class"] });
  });
})();
