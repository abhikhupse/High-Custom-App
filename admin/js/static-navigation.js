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
    headerCss.href = `${new URL(
      "css/admin-shared-header.css",
      getAdminRoot(),
    ).href}?v=20260916-3`;
    document.head.append(headerCss);
  }

  if (!document.getElementById("adminSharedSidebarCss")) {
    const sidebarCss = document.createElement("link");
    sidebarCss.id = "adminSharedSidebarCss";
    sidebarCss.rel = "stylesheet";
    sidebarCss.href = `${new URL("css/admin-sidebar-clean.css", getAdminRoot()).href}?v=20260917-1`;
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
  const signOut = async () => {
    const token = localStorage.getItem("highCustomAdminToken");
    const isLocal = ["localhost", "127.0.0.1"].includes(
      window.location.hostname,
    );
    const apiBase = isLocal
      ? "http://localhost:3000/api"
      : localStorage.getItem("highCustomApiBase") ||
        "https://high-custom-app.onrender.com/api";
    // Logout should never leave the user stuck if the server is unavailable.
    // The browser session is cleared in either case.
    if (token) {
      try {
        await fetch(`${apiBase}/user/logout`, {
          method: "POST",
          headers: { Authorization: `Bearer ${token}` },
          keepalive: true,
        });
      } catch (_) {
        // Local logout still completes below.
      }
    }
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
    if (!header) return;
    const isDashboard = header.classList.contains("premium-topbar");
    const toggle = header.querySelector(".sidebar-toggle");
    const dashboardFilters = header.querySelector("#dashboardHeaderFilters");
    const dashboardThemeToggle = header.querySelector("#themeToggle");
    const saved = JSON.parse(
      localStorage.getItem("highCustomAdminUser") || "{}",
    );
    const name =
      [saved.firstName, saved.lastName].filter(Boolean).join(" ") ||
      saved.name ||
      "Admin";
    // Cached data is only a temporary placeholder; keep its real role until
    // /user/profile refreshes it from the authenticated backend account.
    const savedRole = String(saved.role || "User").trim();
    const role = savedRole === "Admin" ? "Administrator" : savedRole;
    const initials =
      name
        .split(/\s+/)
        .map((part) => part[0])
        .join("")
        .slice(0, 2)
        .toUpperCase() || "A";
    // Every route, including Dashboard, uses this one header shell. Dashboard
    // merely retains its two live filters as a child of the common actions.
    header.className = "top-navbar universal-dashboard-header";
    header.dataset.dashboardHeader = String(isDashboard);
    header.removeAttribute("style");
    header.removeAttribute("data-bs-theme");
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
      <div class="dropdown universal-profile-menu">
        <button class="universal-profile-trigger" type="button" data-bs-toggle="dropdown" aria-expanded="false">
          <span class="universal-profile-avatar" data-shared-profile-avatar>${initials}</span>
          <span class="universal-profile-copy"><strong data-shared-profile-name>${name}</strong><small data-shared-profile-role>${role}</small></span>
          <i class="fas fa-chevron-down"></i>
        </button>
        <ul class="dropdown-menu dropdown-menu-end universal-profile-dropdown">
          <li><a class="dropdown-item" href="${new URL("users/profile.html", adminRoot).href}"><i class="fas fa-user"></i> Profile</a></li>
          <li><a class="dropdown-item integration-page-link" href="${new URL("integrations.html", adminRoot).href}"><i class="fas fa-plug"></i> Integrations</a></li>
          <li><a class="dropdown-item" href="#"><i class="fas fa-gear"></i> Settings</a></li>
          <li><hr class="dropdown-divider"></li>
          <li><a class="dropdown-item text-danger" href="#" id="logoutBtn"><i class="fas fa-right-from-bracket"></i> Logout</a></li>
        </ul>
      </div>`;
    if (isDashboard && dashboardFilters) {
      dashboardFilters.className = "universal-dashboard-filters";
      actions.prepend(dashboardFilters);
    }
    if (isDashboard && dashboardThemeToggle) actions.append(dashboardThemeToggle);
    header.append(actions);
  };

  // The dashboard already uses /user/profile.  Reuse the exact same source on
  // every other Admin page so the header never falls back to a stale role/name.
  const hydrateHeaderProfile = async () => {
    const token = localStorage.getItem("highCustomAdminToken");
    const profile = document.querySelector(".universal-profile-menu");
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
      const avatarBadge = profile.querySelector("[data-shared-profile-avatar]");

      if (nameElement) nameElement.textContent = name;
      if (roleElement) {
        const storedRole = String(user.role || "User").trim();
        roleElement.textContent = storedRole === "Admin" ? "Administrator" : storedRole;
      }

      if (avatarBadge) avatarBadge.textContent = initials;

      localStorage.setItem("highCustomAdminUser", JSON.stringify(user));
    } catch (_) {
      // Keep the cached profile visible if the API is temporarily unavailable.
    }
  };
  upgradeHeader();
  addLogoutControl();
  hydrateHeaderProfile();
  // Some legacy pages also register a jQuery #logoutBtn handler with a dummy
  // URL. Capture the click first so the shared, authenticated logout wins.
  document.addEventListener(
    "click",
    (event) => {
      const logout = event.target.closest("#logoutBtn, #adminGlobalLogout");
      if (!logout) return;
      event.preventDefault();
      event.stopImmediatePropagation();
      signOut();
    },
    true,
  );
  // Legacy templates contain their own profile dropdown markup. Keep this
  // single route handler so the Integrations item works before or after the
  // shared header replaces that legacy markup.
  document.addEventListener("click", (event) => {
    const item = event.target.closest(".dropdown-item, a");
    if (!item || item.textContent.trim().toLowerCase() !== "integrations")
      return;
    event.preventDefault();
    window.location.assign(new URL("integrations.html", adminRoot).href);
  });
  // The two groups intentionally use different routes, even where a screen
  // looks similar. Admin routes load protected company-wide data; Master
  // routes load data derived from the current JWT owner.
  const renderScopedNavigation = () => {
    const nav = document.querySelector(".sidebar .nav-menu");
    if (!nav) return;
    if (nav.dataset.scopedNavigation === "true") return;
    const sidebar = nav.closest(".sidebar");
    if (sidebar) {
      sidebar.className = "sidebar hc-sidebar";
      sidebar.removeAttribute("style");
    }
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
      group("submenu-admin", "Admin", "fa-user-shield", [
        link("Users", "fa-user", "users/index.html"),
        link("Sequences", "fa-layer-group", "master/userMasterList.html"),
        link("Leads", "fa-users", "Leads/total-leads.html?scope=admin"),
        link("Interested Leads", "fa-bullseye", "Leads/total-leads.html?scope=admin&status=interested"),
        link("All Tracking Report", "fa-chart-column", "master/UserSequenceTable.html"),
      ].join("")),
      group("submenu-master", "Master", "fa-database", [
        link("Social Link", "fa-share-nodes", "social/index.html"),
        link("Link", "fa-link", "social/link-document.html"),
        link("Leads", "fa-users", "Leads/index.html"),
        link("Sequences", "fa-layer-group", "master/master-list.html"),
        link("Tracking Report", "fa-chart-line", "reports/campaign.html"),
        link("Interested Leads", "fa-bullseye", "Leads/index.html?status=interested"),
      ].join("")),
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
  document.body.classList.add("shared-navigation-ready");

  document.addEventListener("DOMContentLoaded", () => {
    const header = document.querySelector(".top-navbar.universal-dashboard-header");
    const nav = document.querySelector(".sidebar .nav-menu");
    if (!header && !nav) return;
    new MutationObserver(() => {
      if (header && !header.querySelector(".universal-header-copy")) upgradeHeader();
      const currentNav = document.querySelector(".sidebar .nav-menu");
      if (!currentNav) return;
      if (currentNav && !currentNav.querySelector("#submenu-master")) {
        delete currentNav.dataset.scopedNavigation;
        renderScopedNavigation();
      }
    }).observe(document.body, { childList: true, subtree: true });
  });
  // One permission source for every static Admin page.  The API calculates
  // effective role defaults plus user-specific overrides, so UI visibility
  // and backend enforcement use the same keys.
  const pageRequirement = (url) => {
    const path = url.pathname.toLowerCase();
    const interested = url.searchParams.get("status") === "interested";
    if (path.endsWith("/dashboard.html")) return [["ownDashboard", "allUserDashboard"], "viewDashboard"];
    if (path.endsWith("/integrations.html"))
      return ["integrations", "viewIntegrations"];
    if (path.includes("/users/")) return ["users", "viewUsers"];
    if (path.endsWith("/master/usermasterlist.html"))
      return ["allSequences", "viewAllUsersSequences"];
    if (path.endsWith("/master/usersequencetable.html"))
      return ["allTrackingReport", "viewAllUsersTracking"];
    if (path.endsWith("/leads/total-leads.html"))
      return interested
        ? ["allInterestedLeads", "viewAllInterestedLeads"]
        : ["allLeads", "viewAllUsersLeads"];
    if (path.endsWith("/leads/index.html"))
      return interested
        ? ["interestedLeads", "viewInterestedLeads"]
        : ["leads", "viewLeads"];
    if (path.endsWith("/master/master-list.html"))
      return ["sequences", "viewSequences"];
    if (path.endsWith("/reports/campaign.html"))
      return ["trackingReport", "viewTrackingReport"];
    if (path.includes("/social/") && path.includes("link-document"))
      return ["businessLink", "viewBusinessLink"];
    if (path.includes("/social/")) return ["socialLinks", "viewSocialLinks"];
    return null;
  };
  const denyPage = () => {
    document.body.replaceChildren();
    const notice = document.createElement("main");
    notice.style.cssText =
      "min-height:100vh;display:grid;place-items:center;background:#f5f7fb;padding:24px;font:600 16px Arial,sans-serif;color:#10213d";
    notice.innerHTML =
      '<section style="max-width:430px;text-align:center;background:#fff;padding:36px;border-radius:16px;box-shadow:0 12px 35px #15294a1c"><h1 style="margin:0 0 10px">Access denied</h1><p style="margin:0 0 22px;color:#61708a;font-weight:400">You do not have permission to open this page.</p><a href="' +
      new URL("dashboard.html", adminRoot).href +
      '" style="display:inline-block;background:#a8751f;color:#fff;text-decoration:none;padding:11px 17px;border-radius:8px">Go back</a></section>';
    document.body.append(notice);
  };
  const applyUserPermissions = (user) => {
    const allowed = (requirement) => {
      if (!requirement) return true;
      const [appRequirement, accessRequirement] = requirement;
      const hasAppRight = Array.isArray(appRequirement)
        ? appRequirement.some((right) => user.appRights?.[right] === true)
        : user.appRights?.[appRequirement] === true;
      return hasAppRight && user.accessRights?.[accessRequirement] === true;
    };
    document.querySelectorAll(".sidebar a.nav-link[href]").forEach((link) => {
      const requirement = pageRequirement(
        new URL(link.href, window.location.origin),
      );
      link.closest(".nav-item").hidden = !allowed(requirement);
    });
    document.querySelectorAll(".sidebar .sub-menu").forEach((menu) => {
      const children = [...menu.querySelectorAll(":scope > .nav-item")];
      const group = menu.closest(".nav-item");
      if (group)
        group.hidden =
          children.length > 0 && children.every((child) => child.hidden);
    });
    return allowed;
  };

  const applyPermissions = async () => {
    const revealShell = () =>
      document.documentElement.classList.add("hc-shell-ready");
    const token = localStorage.getItem("highCustomAdminToken");
    if (!token) {
      revealShell();
      return;
    }
    // The login flow stores the signed-in user's profile. Apply those rights
    // synchronously so navigation remains stable while the fresh request runs.
    try {
      const cachedUser = JSON.parse(
        localStorage.getItem("highCustomAdminUser") || "null",
      );
      if (cachedUser?.appRights && cachedUser?.accessRights) {
        applyUserPermissions(cachedUser);
        revealShell();
      }
    } catch (_) {
      // A malformed old cache is ignored and the authenticated request below
      // becomes the source of truth.
    }
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
      localStorage.setItem("highCustomAdminUser", JSON.stringify(user));
      const allowed = applyUserPermissions(user);
      if (!allowed(pageRequirement(new URL(window.location.href)))) denyPage();
    } catch (_) {
      // Existing backend route protection remains the security boundary if a
      // temporary connection failure prevents the visual update.
    } finally {
      // Do not expose the generated navigation until its permissions have
      // been applied. This prevents restricted groups such as Admin from
      // flashing briefly while the profile request is in progress.
      revealShell();
    }
  };
  applyPermissions();


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
    document
      .querySelectorAll(".sidebar [data-target]")
      .forEach((button) => button.classList.remove("active-indicator"));
    const match = links.find((link) => {
      const target = new URL(link.href, window.location.origin);
      return (
        target.pathname.replace(/\/$/, "") ===
          current.pathname.replace(/\/$/, "") &&
        target.search === current.search
      );
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
        return (
          target.pathname.replace(/\/$/, "") ===
            current.pathname.replace(/\/$/, "") &&
          target.search === current.search
        );
      });
      if (
        expected &&
        (!expected.classList.contains("active") ||
          links.some(
            (link) => link !== expected && link.classList.contains("active"),
          ))
      ) {
        applyScopedActiveState();
      }
    });
    observer.observe(nav, {
      attributes: true,
      subtree: true,
      attributeFilter: ["class"],
    });
  });
})();
