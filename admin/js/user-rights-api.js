document.addEventListener("DOMContentLoaded", () => {
  "use strict";

  // ============================================================
  // HELPERS
  // ============================================================

  const $ = (id) => document.getElementById(id);

  const isLocal = ["localhost", "127.0.0.1"].includes(location.hostname);
  const api = isLocal
    ? "http://localhost:3000/api"
    : localStorage.getItem("highCustomApiBase") ||
      "https://high-custom-app.onrender.com/api";

  const token = localStorage.getItem("highCustomAdminToken");

  // ============================================================
  // AUTH CHECK
  // ============================================================

  if (!token) {
    location.replace("/admin-login.html");
    return;
  }

  // ============================================================
  // STATE
  // ============================================================

  let currentUserId = null;
  let currentUserRole = "Admin";

  let users = [];

  let availableRoles = ["Employee", "HR", "Admin"];

  let inactiveOnly = false;

  let selectedUser = null;
  let selectedEditor = null;

  // ============================================================
  // ESCAPE HTML
  // ============================================================

  const escapeHtml = (value) =>
    String(value ?? "").replace(/[&<>"']/g, (character) => {
      return {
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#39;",
      }[character];
    });

  // ============================================================
  // MESSAGE
  // ============================================================

  function message(text = "") {
    const element = $("userApiMessage");

    if (!element) return;

    element.textContent = text;

    element.classList.toggle("d-none", !text);
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  function successAlert(text) {
    if (window.Swal) {
      Swal.fire({
        icon: "success",
        title: "Success",
        text,
        timer: 1400,
        showConfirmButton: false,
      });

      return;
    }

    alert(text);
  }

  // ============================================================
  // ERROR
  // ============================================================

  function errorAlert(text) {
    if (window.Swal) {
      Swal.fire({
        icon: "error",
        title: "Error",
        text,
      });

      return;
    }

    alert(text);
  }

  // ============================================================
  // API REQUEST
  // ============================================================

  async function request(path, options = {}) {
    const headers = {
      Accept: "application/json",

      Authorization: `Bearer ${token}`,

      ...(options.body && !(options.body instanceof FormData)
        ? {
            "Content-Type": "application/json",
          }
        : {}),

      ...(options.headers || {}),
    };

    const response = await fetch(api + path, {
      ...options,
      headers,
    });

    const data = await response.json().catch(() => ({}));

    // ========================================================
    // TOKEN EXPIRED
    // ========================================================

    if (response.status === 401) {
      localStorage.removeItem("highCustomAdminToken");

      location.replace("/admin-login.html?reason=access");

      throw new Error("Session expired.");
    }

    // ========================================================
    // API ERROR
    // ========================================================

    if (!response.ok || data.success === false) {
      throw new Error(data.message || "Request failed.");
    }

    return data;
  }

  // ============================================================
  // USER HELPERS
  // ============================================================

  function isSelf(user) {
    return String(user?._id) === String(currentUserId);
  }

  function isAdmin(user) {
    return user?.role === "Admin" || user?.isAdministrator === true;
  }

  function isPrimaryAdmin(user) {
    return user?.isPrimaryAdministrator === true;
  }

  function isCurrentUserPrimaryAdmin() {
    return isPrimaryAdmin(users.find((user) => isSelf(user)));
  }

  function isHR(user) {
    return user?.role === "HR";
  }

  function normalizeRole(role) {
    return role === "User" ? "Employee" : role || "Admin";
  }

  function canCurrentUserManage(user) {
    if (!user || isSelf(user)) {
      return false;
    }

    // ADMIN
    if (currentUserRole === "Admin") {
      // A main Admin can manage every created account, including another
      // Admin. Only the configured primary Admin is protected.
      return !isPrimaryAdmin(user);
    }

    // HR
    if (currentUserRole === "HR") {
      return user.role === "Employee";
    }

    return false;
  }

  function canDelete(user) {
    return currentUserRole === "Admin" && !isSelf(user) && !isAdmin(user);
  }

  function canManageAppRights(user) {
    return (
      currentUserRole === "Admin" &&
      Boolean(user) &&
      (!isPrimaryAdmin(user) || isCurrentUserPrimaryAdmin())
    );
  }

  function canManageAccessRights(user) {
    if (currentUserRole === "Admin") {
      return (
        Boolean(user) && (!isPrimaryAdmin(user) || isCurrentUserPrimaryAdmin())
      );
    }
    return canCurrentUserManage(user);
  }

  function canEditProfile(user) {
    if (!user) {
      return false;
    }

    // An Administrator can edit an administrator's basic profile, including
    // their own profile. Role, account status and permission controls remain
    // separately protected by the backend.
    if (currentUserRole === "Admin" && isAdmin(user)) {
      return !isPrimaryAdmin(user) || isCurrentUserPrimaryAdmin();
    }

    if (isSelf(user)) return false;

    return (
      currentUserRole === "Admin" ||
      (currentUserRole === "HR" && user.role === "Employee")
    );
  }

  // ============================================================
  // ROLE CLASS
  // ============================================================

  function roleClass(user) {
    if (isPrimaryAdmin(user)) {
      return "role-administrator";
    }

    if (isAdmin(user)) {
      return "role-sub-admin";
    }

    if (isHR(user)) {
      return "role-hr";
    }

    return "role-employee";
  }

  function roleLabel(user) {
    if (isPrimaryAdmin(user)) return "Administrator";
    if (isAdmin(user)) return "Sub Admin";
    return user?.role || "Employee";
  }

  function populateRoleSelect(selectedRole = "Employee") {
    const select = $("role");
    if (!select) return;
    const roles = [...new Set(availableRoles)];
    select.innerHTML = roles
      .map(
        (role) =>
          `<option value="${escapeHtml(role)}">${escapeHtml(role === "Admin" ? "Sub Admin" : role)}</option>`,
      )
      .join("");
    select.value = roles.includes(selectedRole) ? selectedRole : "Employee";
    renderRolePicker();
  }

  function roleDisplayName(role) {
    return role === "Admin" ? "Sub Admin" : role;
  }

  function rolePickerIcon(role) {
    if (role === "Admin") return "fa-crown";
    if (role === "HR") return "fa-user-tie";
    if (role === "Employee") return "fa-user";
    return "fa-user-tag";
  }

  function renderRolePicker() {
    const select = $("role");
    const picker = $("rolePicker");
    const value = $("rolePickerValue");
    const menu = $("rolePickerMenu");
    const trigger = $("rolePickerToggle");
    if (!select || !picker || !value || !menu || !trigger) return;

    const roles = [...select.options].map((option) => option.value);
    value.textContent = roleDisplayName(select.value || "Employee");
    trigger.disabled = select.disabled;
    picker.classList.toggle("is-disabled", select.disabled);
    menu.innerHTML = roles
      .map((role) => `<button type="button" class="user-role-option${role === select.value ? " is-selected" : ""}" data-role="${escapeHtml(role)}"><i class="fas ${rolePickerIcon(role)}"></i>${escapeHtml(roleDisplayName(role))}</button>`)
      .join("");
  }

  async function createCustomRole(name) {
    const roleName = String(name || "")
      .trim()
      .replace(/\s+/g, " ");
    if (!roleName) return;

    try {
      const result = await request("/admin/users/roles", {
        method: "POST",
        body: JSON.stringify({ name: roleName }),
      });
      const createdRole = result.data?.name || roleName;
      availableRoles = [...new Set([...availableRoles, createdRole])];
      populateRoleSelect(createdRole);
      $("customRoleName").value = "";
      $("customRoleControls").classList.add("d-none");
      successAlert(result.message || "New role added.");
    } catch (error) {
      errorAlert(error.message);
    }
  }

  function addCustomRole() {
    if (!isCurrentUserPrimaryAdmin()) {
      errorAlert("Only the main Administrator can add roles.");
      return;
    }

    const controls = $("customRoleControls");
    const input = $("customRoleName");
    controls?.classList.remove("d-none");
    input?.focus();
  }

  // ============================================================
  // DATA SCOPE LABEL
  // ============================================================

  function scopeLabel(scope) {
    switch (scope) {
      case "all":
        return "All System Data";

      case "company":
        return "Company Data";

      case "assigned":
        return "Own + Assigned";

      default:
        return "Own Data";
    }
  }

  // ============================================================
  // FILTER USERS
  // ============================================================

  function filteredUsers() {
    const searchElement = $("globalSearch");

    const query = searchElement ? searchElement.value.trim().toLowerCase() : "";
    const selectedRole = $("roleFilter")?.value || "";
    const selectedStatus = $("statusFilter")?.value || "";
    const selectedDate = $("dateFilter")?.value || "";
    const now = new Date();

    return users.filter((user) => {
      if (inactiveOnly && user.isActive !== false) {
        return false;
      }
      if (selectedRole && user.role !== selectedRole) return false;
      if (selectedStatus === "active" && user.isActive === false) return false;
      if (selectedStatus === "inactive" && user.isActive !== false)
        return false;
      if (selectedDate) {
        const createdAt = user.createdAt ? new Date(user.createdAt) : null;
        const days =
          selectedDate === "today" ? 1 : selectedDate === "week" ? 7 : 30;
        if (!createdAt || now - createdAt > days * 86400000) return false;
      }

      const searchable = [
        user.employerCode,
        user.firstName,
        user.lastName,
        user.phone,
        user.email,
        user.role,
      ]
        .join(" ")
        .toLowerCase();

      return searchable.includes(query);
    });
  }

  // ============================================================
  // SORT USERS
  // ============================================================

  function sortUsers(list) {
    const roleWeight = {
      Admin: 3,
      HR: 2,
      Employee: 1,
    };

    return [...list].sort((first, second) => {
      return (roleWeight[second.role] || 0) - (roleWeight[first.role] || 0);
    });
  }

  // ============================================================
  // RENDER USERS
  // ============================================================

  function render() {
    const table = $("usersTable");

    if (!table) {
      console.error("usersTable not found.");
      return;
    }

    const tbody = table.querySelector("tbody");

    if (!tbody) {
      console.error("usersTable tbody not found.");
      return;
    }

    const rows = sortUsers(filteredUsers());

    const setSummary = (id, value) => {
      const element = $(id);
      if (element) element.textContent = value;
    };
    const activeUsers = users.filter((user) => user.isActive !== false);
    const administrators = users.filter((user) => user.isPrimaryAdministrator);
    const subAdmins = users.filter(
      (user) => isAdmin(user) && !user.isPrimaryAdministrator,
    );
    setSummary("summaryTotalUsers", users.length);
    setSummary("summaryActiveUsers", activeUsers.length);
    setSummary("summaryInactiveUsers", users.length - activeUsers.length);
    setSummary("summaryAdministrators", administrators.length);
    setSummary("summarySubAdmins", subAdmins.length);
    setSummary(
      "summaryEmployees",
      users.filter((user) => !isAdmin(user) && !isHR(user)).length,
    );

    const totalElement = $("totalUsersCount");

    if (totalElement) {
      totalElement.textContent = `Total Users: ${rows.length}`;
    }

    if (!rows.length) {
      tbody.innerHTML = `
        <tr>
          <td colspan="10" class="text-center py-4 text-muted">
            No users found.
          </td>
        </tr>
      `;

      return;
    }

    tbody.innerHTML = rows
      .map((user) => {
        const manageable = canCurrentUserManage(user);
        const appRightsManageable = canManageAppRights(user);
        const accessRightsManageable = canManageAccessRights(user);

        const deletable = canDelete(user);

        const editable = canEditProfile(user);

        const self = isSelf(user);

        const admin = isAdmin(user);

        return `
          <tr
            data-id="${escapeHtml(user._id)}"
            class="${admin ? "administrator-row" : ""}"
          >

            <td>
              <button
                type="button"
                class="edit-user-btn"
                data-action="edit"
                ${!editable ? "disabled" : ""}
                title="${
                  self
                    ? "You cannot edit yourself here"
                    : !editable
                      ? "You cannot manage this user"
                      : "Edit User"
                }"
              >
                <i class="fas fa-pen"></i>
              </button>
            </td>

            <td>
              ${escapeHtml(user.employerCode)}
            </td>

            <td>
              <div class="user-name-cell">
                <span class="user-row-avatar">${escapeHtml(`${user.firstName || ""}`.trim().slice(0, 1) || "U")}</span>
                <span>${escapeHtml(user.firstName)} ${escapeHtml(user.lastName)}

              ${
                self
                  ? `
                    <small class="text-muted">
                      (You)
                    </small>
                  `
                  : ""
              }
                </span>
              </div>
            </td>

            <td>
              <span class="user-contact"><i class="fas fa-phone"></i>${escapeHtml(user.phone)}</span>
            </td>

            <td>
              <span class="user-contact"><i class="far fa-envelope"></i>${escapeHtml(user.email)}</span>
            </td>

            <td>
              <span
                class="role-badge ${roleClass(user)}"
              >
                ${
                  admin
                    ? `
                      <i class="fas fa-crown"></i>
                    `
                    : ""
                }

                ${escapeHtml(roleLabel(user))}
              </span>
            </td>

            <td class="text-center">
              <button
                type="button"
                class="rights-edit-btn rights-view-btn"
                data-action="app"
                ${!appRightsManageable ? "disabled" : ""}
                title="Edit App Rights"
              >
                <i class="fas fa-border-all"></i>View
              </button>
            </td>

            <td class="text-center">
              <button
                type="button"
                class="rights-edit-btn rights-view-btn"
                data-action="access"
                ${!accessRightsManageable ? "disabled" : ""}
                title="Edit Access Rights"
              >
                <i class="fas fa-shield-halved"></i>View
              </button>
            </td>

            <td class="text-center">
              <div class="status-control ${user.isActive ? "status-active" : "status-inactive"}">
                <span class="status-label">${user.isActive ? "Active" : "Inactive"}</span>
                <div class="form-check form-switch m-0">
                <input
                  type="checkbox"
                  class="form-check-input"
                  data-action="status"
                  ${user.isActive ? "checked" : ""}
                  ${!manageable ? "disabled" : ""}
                >
                </div>
              </div>
            </td>

            <td class="text-center">
              <button
                type="button"
                class="delete-user-btn"
                data-action="delete"
                ${!deletable ? "disabled" : ""}
                title="${
                  deletable ? "Delete User" : "Only Admin can delete this user"
                }"
              >
                <i class="fas fa-trash"></i>
              </button>
            </td>

          </tr>
        `;
      })
      .join("");
  }

  // ============================================================
  // REPLACE USER LOCALLY
  // ============================================================

  function replaceUser(updatedUser) {
    users = users.map((user) =>
      String(user._id) === String(updatedUser._id) ? updatedUser : user,
    );
  }

  // ============================================================
  // UPDATE USER
  // ============================================================

  async function updateUser(userId, payload) {
    const result = await request(`/admin/users/${userId}`, {
      method: "PATCH",

      body: payload instanceof FormData ? payload : JSON.stringify(payload),
    });

    replaceUser(result.data);

    render();

    return result.data;
  }

  // ============================================================
  // LOAD APP RIGHTS
  // ============================================================

  function loadAppRights(user) {
    const rights = user.appRights || {};

    document.querySelectorAll(".app-right-check").forEach((checkbox) => {
      checkbox.disabled = false;

      checkbox.checked = rights[checkbox.value] === true;
    });

    enhanceAppRightsEditor();

    applyAppRestrictions(user);
  }

  // Keep the existing inputs and save behaviour, but give App Rights the
  // richer module-directory presentation used by the new Admin design.
  function enhanceAppRightsEditor() {
    const meta = {
      dashboard: ["Dashboard", "View key metrics, analytics and overview.", "fa-house", ""],
      users: ["Users", "View and manage all users.", "fa-users", "purple"],
      leads: ["Leads", "Manage and track all leads.", "fa-users-viewfinder", "green"],
      interestedLeads: ["Interested Leads", "View and manage interested leads.", "fa-star", "gold"],
      sequences: ["Sequences", "Create and manage email sequences.", "fa-rectangle-list", "purple"],
      trackingReport: ["Tracking Report", "View email tracking and campaign reports.", "fa-chart-column", ""],
      socialLinks: ["Social Links", "Manage social media links.", "fa-share-nodes", "pink"],
      businessLink: ["Business Link", "Manage business and custom links.", "fa-link", ""],
      integrations: ["Integrations", "Connect and manage email services.", "fa-plug", "green"],
      notifications: ["Notifications", "View account notifications.", "fa-bell", "gold"],
      profile: ["Own Profile", "View and manage the personal profile.", "fa-user", "purple"],
      appRightsManagement: ["Manage App Rights", "Manage module visibility for users.", "fa-grip", "red"],
      accessRightsManagement: ["Manage Access Rights", "Manage actions allowed inside modules.", "fa-shield-halved", "red"],
      allSequences: ["All Sequences", "View and manage all users' sequences.", "fa-rectangle-list", ""],
      allLeads: ["All Leads", "View and manage all users' leads.", "fa-users-viewfinder", "green"],
      allTrackingReport: ["All Tracking Report", "View tracking reports for all users.", "fa-chart-column", ""],
      allInterestedLeads: ["All Interested Leads", "View and manage all users' interested leads.", "fa-star", "gold"],
    };
    const checks = [...document.querySelectorAll(".app-right-check")];
    checks.forEach((input) => {
      const label = input.closest("label.rights-option");
      const detail = meta[input.value];
      if (!label || !detail) return;
      if (!label.dataset.premiumReady) {
        label.dataset.premiumReady = "true";
        const icon = document.createElement("span");
        icon.className = `app-right-icon ${detail[3]}`;
        icon.innerHTML = `<i class="fas ${detail[2]}"></i>`;
        const copy = document.createElement("span");
        copy.className = "app-right-copy";
        copy.innerHTML = `<strong>${detail[0]}</strong><small>${detail[1]}</small>`;
        label.replaceChildren(input, icon, copy);
        input.addEventListener("change", () => updateAppRightsPresentation());
      }
    });
    buildAppRightsHierarchy();
    const search = $("appRightsSearch");
    if (search && !search.dataset.bound) {
      search.dataset.bound = "true";
      search.addEventListener("input", () => {
        const term = search.value.trim().toLowerCase();
        document.querySelectorAll("#appRightsEditor .rights-option").forEach((card) => {
          card.hidden = term && !card.textContent.toLowerCase().includes(term);
        });
      });
      $("expandAppRights")?.addEventListener("click", () => {
        search.value = "";
        document.querySelectorAll("#appRightsEditor .rights-option").forEach((card) => (card.hidden = false));
      });
      $("collapseAppRights")?.addEventListener("click", () => {
        document.querySelectorAll("#appRightsEditor .rights-option").forEach((card) => {
          card.hidden = !card.querySelector(".app-right-check")?.checked;
        });
      });
    }
    updateAppRightsPresentation();
  }

  function buildAppRightsHierarchy() {
    const editor = $("appRightsEditor");
    const grid = editor?.querySelector(".rights-option-grid");
    if (!editor || !grid || editor.dataset.hierarchyReady) return;
    editor.dataset.hierarchyReady = "true";
    const card = (key) => grid.querySelector(`.app-right-check[value="${key}"]`)?.closest(".rights-option");
    const take = (key) => card(key);
    const group = (title, description, icon, keys, tone) => {
      const host = document.createElement("section");
      host.className = "rights-module-group";
      host.innerHTML = `<label class="rights-group-head"><input class="form-check-input rights-group-check" type="checkbox"><span class="app-right-icon ${tone}"><i class="fas ${icon}"></i></span><span class="app-right-copy"><strong>${title}</strong><small>${description}</small></span><i class="fas fa-chevron-up rights-group-arrow"></i></label><div class="rights-group-items"></div>`;
      const toggle = host.querySelector(".rights-group-check");
      const items = host.querySelector(".rights-group-items");
      keys.forEach((key) => { const item = take(key); if (item) items.append(item); });
      toggle.addEventListener("change", () => {
        items.querySelectorAll(".app-right-check:not(:disabled)").forEach((input) => {
          input.checked = toggle.checked;
          input.dispatchEvent(new Event("change"));
        });
      });
      host.querySelector(".rights-group-head").addEventListener("click", (event) => {
        if (event.target.closest("input")) return;
        host.classList.toggle("is-collapsed");
      });
      return host;
    };
    const layout = document.createElement("div");
    layout.className = "rights-app-layout";
    const left = document.createElement("div");
    const right = document.createElement("div");
    left.className = right.className = "rights-app-column";
    const dashboard = take("dashboard");
    if (dashboard) left.append(dashboard);
    left.append(group("Master", "Manage master data and resources.", "fa-layer-group", ["socialLinks", "businessLink", "sequences", "trackingReport"], "purple"));
    const leads = take("leads"); const interested = take("interestedLeads");
    if (leads) right.append(leads);
    if (interested) right.append(interested);
    right.append(group("Admin", "Manage users, data and system settings.", "fa-gear", ["users", "allSequences", "allLeads", "allTrackingReport", "allInterestedLeads"], "pink"));
    const other = ["integrations", "notifications", "profile", "appRightsManagement", "accessRightsManagement"].map(take).filter(Boolean);
    if (other.length) {
      const more = document.createElement("section");
      more.className = "rights-more-modules";
      more.innerHTML = '<h6>Additional Modules</h6><div class="rights-group-items"></div>';
      other.forEach((item) => more.querySelector(".rights-group-items").append(item));
      right.append(more);
    }
    layout.append(left, right);
    grid.replaceWith(layout);
  }

  function updateAppRightsPresentation() {
    const checks = [...document.querySelectorAll(".app-right-check")];
    checks.forEach((input) => input.closest(".rights-option")?.classList.toggle("is-checked", input.checked));
    document.querySelectorAll(".rights-module-group").forEach((group) => {
      const inputs = [...group.querySelectorAll(".rights-group-items .app-right-check")];
      const toggle = group.querySelector(".rights-group-check");
      if (!toggle || !inputs.length) return;
      toggle.checked = inputs.every((input) => input.checked);
      toggle.indeterminate = !toggle.checked && inputs.some((input) => input.checked);
    });
    const count = $("rightsSelectedCount");
    if (count) count.textContent = `${checks.filter((input) => input.checked).length} / ${checks.length}`;
  }

  // ============================================================
  // APP RESTRICTIONS
  // ============================================================

  function applyAppRestrictions(user) {
    const checkboxes = document.querySelectorAll(".app-right-check");

    if (currentUserRole === "Admin") {
      return;
    }

    if (currentUserRole === "HR" && user.role === "Employee") {
      const blocked = [
        "users",
        "appRightsManagement",
        "accessRightsManagement",
      ];

      checkboxes.forEach((checkbox) => {
        if (blocked.includes(checkbox.value)) {
          checkbox.disabled = true;
        }
      });

      return;
    }

    checkboxes.forEach((checkbox) => {
      checkbox.disabled = true;
    });
  }

  // ============================================================
  // LOAD ACCESS RIGHTS
  // ============================================================

  function loadAccessRights(user) {
    const rights = user.accessRights || {};

    document.querySelectorAll(".access-right-check").forEach((checkbox) => {
      checkbox.disabled = false;

      checkbox.checked = rights[checkbox.value] === true;
    });

    enhanceAccessRightsEditor();

    applyAccessRestrictions(user);
  }

  function enhanceAccessRightsEditor() {
    const editor = $("accessRightsEditor");
    const grid = editor?.querySelector(".rights-option-grid");
    if (!editor) return;
    if (editor.dataset.premiumReady) {
      updateAccessRightsPresentation();
      return;
    }
    if (grid) {
      editor.dataset.premiumReady = "true";
      const take = (key) => grid.querySelector(`.access-right-check[value="${key}"]`)?.closest(".rights-option");
      const module = (title, description, icon, tone, keys) => {
        const card = document.createElement("section");
        card.className = "access-module-card is-collapsed";
        card.innerHTML = `<button type="button" class="access-module-head" aria-expanded="false"><span class="app-right-icon ${tone}"><i class="fas ${icon}"></i></span><span><strong>${title}</strong><small>${description}</small></span><i class="fas fa-chevron-down access-module-arrow"></i></button><div class="access-permissions"></div>`;
        const list = card.querySelector(".access-permissions");
        keys.forEach((key) => {
          const item = take(key);
          if (!item) return;
          // Screen/page visibility is controlled in Application Rights, so
          // View permissions are intentionally not shown in Access Rights.
          if (key.startsWith("view")) item.dataset.viewRight = "true";
          list.append(item);
        });
        if (!list.children.length) card.classList.add("is-empty");
        card.querySelector(".access-module-head").addEventListener("click", () => {
          const opening = card.classList.contains("is-collapsed");
          editor.querySelectorAll(".access-module-card:not(.is-collapsed)").forEach((other) => {
            other.classList.add("is-collapsed");
            other.querySelector(".access-module-head")?.setAttribute("aria-expanded", "false");
          });
          card.classList.toggle("is-collapsed", !opening);
          card.querySelector(".access-module-head").setAttribute("aria-expanded", String(opening));
        });
        return card;
      };
      const layout = document.createElement("div");
      layout.className = "rights-access-layout";
      const leftColumn = document.createElement("div");
      const rightColumn = document.createElement("div");
      leftColumn.className = rightColumn.className = "rights-access-column";
      leftColumn.append(
        module("Leads", "Manage and track all leads.", "fa-users", "green", ["viewLeads", "viewAllUsersLeads", "createLead", "editLead", "deleteLead", "importLeads", "exportLeads"]),
        module("Business Link", "Manage business and custom links.", "fa-id-card", "purple", ["viewBusinessLink", "createBusinessLink", "editBusinessLink", "deleteBusinessLink"]),
        module("Tracking Report", "Manage tracking reports.", "fa-chart-column", "green", ["viewTrackingReport", "viewAllUsersTracking", "exportTrackingReport"]),
        module("Users", "Manage employees and user settings.", "fa-user-shield", "gold", ["viewUsers", "viewUserDetails", "createEmployee", "editEmployee", "deleteEmployee", "activateDeactivateEmployee", "changeEmployeeRole", "manageHR", "manageAdmin"]),
      );
      rightColumn.append(
        module("Social Links", "Manage social media links.", "fa-share-nodes", "pink", ["viewSocialLinks", "createSocialLink", "editSocialLink", "deleteSocialLink"]),
        module("Sequences", "Manage email sequences.", "fa-layer-group", "purple", ["viewSequences", "viewAllUsersSequences", "createSequence", "editSequence", "deleteSequence", "runSequence"]),
        module("Integration", "Manage integrations such as Gmail and Zoho.", "fa-link", "", ["viewIntegrations", "connectIntegration", "disconnectIntegration"]),
        module("Other Actions", "Profile, notifications and permission controls.", "fa-shield-halved", "", ["viewDashboard", "viewCompanyDashboard", "viewInterestedLeads", "viewAllInterestedLeads", "editInterestedLead", "deleteInterestedLead", "exportInterestedLeads", "viewNotifications", "markNotificationRead", "deleteNotification", "viewProfile", "editProfile", "manageEmployeeAppRights", "manageEmployeeAccessRights", "manageHRAppRights", "manageHRAccessRights"]),
      );
      layout.append(leftColumn, rightColumn);
      // Preserve any current or future backend permission that is not in a
      // named group above; it must remain editable and saveable.
      const remaining = [...grid.querySelectorAll(".rights-option")];
      if (remaining.length) {
        const extra = document.createElement("section");
        extra.className = "access-module-card is-collapsed";
        extra.innerHTML = '<button type="button" class="access-module-head" aria-expanded="false"><span class="app-right-icon blue"><i class="fas fa-sliders"></i></span><span><strong>Additional Permissions</strong><small>Other available actions for this user.</small></span><i class="fas fa-chevron-down access-module-arrow"></i></button><div class="access-permissions"></div>';
        const list = extra.querySelector(".access-permissions");
        remaining.forEach((item) => {
          if (item.querySelector(".access-right-check")?.value.startsWith("view")) item.dataset.viewRight = "true";
          list.append(item);
        });
        extra.querySelector(".access-module-head").addEventListener("click", () => {
          const opening = extra.classList.contains("is-collapsed");
          editor.querySelectorAll(".access-module-card:not(.is-collapsed)").forEach((other) => {
            other.classList.add("is-collapsed");
            other.querySelector(".access-module-head")?.setAttribute("aria-expanded", "false");
          });
          extra.classList.toggle("is-collapsed", !opening);
          extra.querySelector(".access-module-head").setAttribute("aria-expanded", String(opening));
        });
        rightColumn.append(extra);
      }
      grid.replaceWith(layout);
      const search = $("accessRightsSearch");
      search?.addEventListener("input", () => {
        const term = search.value.trim().toLowerCase();
        editor.querySelectorAll(".access-module-card").forEach((card) => {
          const show = !term || card.textContent.toLowerCase().includes(term);
          card.hidden = !show;
          if (show && term) {
            card.classList.remove("is-collapsed");
            card.querySelector(".access-module-head")?.setAttribute("aria-expanded", "true");
          }
        });
      });
      $("selectAllAccessRights")?.addEventListener("click", () => {
        editor.querySelectorAll(".rights-option:not([data-view-right]) .access-right-check:not(:disabled)").forEach((input) => { input.checked = true; input.dispatchEvent(new Event("change")); });
      });
      $("deselectAllAccessRights")?.addEventListener("click", () => {
        editor.querySelectorAll(".rights-option:not([data-view-right]) .access-right-check:not(:disabled)").forEach((input) => { input.checked = false; input.dispatchEvent(new Event("change")); });
      });
      editor.querySelectorAll(".access-right-check").forEach((input) => input.addEventListener("change", updateAccessRightsPresentation));
    }
    updateAccessRightsPresentation();
  }

  function updateAccessRightsPresentation() {
    const checks = [...document.querySelectorAll(".rights-option:not([data-view-right]) .access-right-check")];
    const count = $("rightsSelectedCount");
    if (count) count.textContent = `${checks.filter((input) => input.checked).length} / ${checks.length}`;
  }

  // ============================================================
  // ACCESS RESTRICTIONS
  // ============================================================

  function applyAccessRestrictions(user) {
    const checkboxes = document.querySelectorAll(".access-right-check");

    if (currentUserRole === "Admin") {
      return;
    }

    // ========================================================
    // HR -> EMPLOYEE ONLY
    // ========================================================

    if (currentUserRole === "HR" && user.role === "Employee") {
      const blocked = [
        "manageHR",
        "manageAdmin",

        "manageHRAppRights",
        "manageHRAccessRights",

        "changeEmployeeRole",
      ];

      checkboxes.forEach((checkbox) => {
        if (blocked.includes(checkbox.value)) {
          checkbox.disabled = true;
        }
      });

      return;
    }

    // Everyone else blocked.
    checkboxes.forEach((checkbox) => {
      checkbox.disabled = true;
    });

  }

  // ============================================================
  // OPEN RIGHTS MODAL
  // ============================================================

  function openRightsModal(user, type) {
    selectedUser = user;
    selectedEditor = type;

    const name = $("rightsUserName");

    if (name) {
      name.textContent =
        `${user.firstName || ""} ${user.lastName || ""}`.trim();
    }

    const employeeCode = $("rightsEmployeeCode");

    if (employeeCode) {
      employeeCode.textContent = user.employerCode || "—";
    }

    const dataScope = $("rightsDataScope");

    if (dataScope) {
      dataScope.textContent = scopeLabel(user.dataScope);
    }

    const roleBadge = $("rightsUserRole");

    if (roleBadge) {
      roleBadge.className = `role-badge ${roleClass(user)}`;

      roleBadge.textContent = roleLabel(user);
    }

    const appEditor = $("appRightsEditor");

    const accessEditor = $("accessRightsEditor");

    // ========================================================
    // APP
    // ========================================================

    if (type === "app") {
      const title = $("rightsModalTitle");

      if (title) {
        title.textContent = "Application Rights";
      }
      const titleIcon = document.querySelector(".rights-title-icon i");
      if (titleIcon) titleIcon.className = "fas fa-grip";
      const selectionLabel = document.querySelector(".rights-selection-count span");
      if (selectionLabel) selectionLabel.textContent = "Modules Selected";

      const description = $("rightsHeaderDescription");
      if (description) {
        description.textContent = "Choose which app modules this person can access. Selected modules will be visible in the sidebar and accessible to the user.";
      }
      const noteTitle = document.querySelector("#appRightsNote strong");
      const noteText = document.querySelector("#appRightsNote small");
      if (noteTitle) noteTitle.textContent = "Application Rights control which modules and pages are visible to the user.";
      if (noteText) noteText.textContent = "Use Access Rights to decide which actions they can perform inside those modules.";

      appEditor?.classList.remove("d-none");

      accessEditor?.classList.add("d-none");

      loadAppRights(user);
    }

    // ========================================================
    // ACCESS
    // ========================================================
    else {
      const title = $("rightsModalTitle");

      if (title) {
        title.textContent = "Access Rights";
      }
      const titleIcon = document.querySelector(".rights-title-icon i");
      if (titleIcon) titleIcon.className = "fas fa-shield-halved";
      const selectionLabel = document.querySelector(".rights-selection-count span");
      if (selectionLabel) selectionLabel.textContent = "Rights Selected";

      const description = $("rightsHeaderDescription");
      if (description) {
        description.textContent = "Choose which actions this person can perform inside the permitted modules.";
      }
      const noteTitle = document.querySelector("#appRightsNote strong");
      const noteText = document.querySelector("#appRightsNote small");
      if (noteTitle) noteTitle.textContent = "Access Rights control which actions the user can perform inside each module.";
      if (noteText) noteText.textContent = "Page and sidebar visibility is managed separately through Application Rights.";

      accessEditor?.classList.remove("d-none");

      appEditor?.classList.add("d-none");

      loadAccessRights(user);
    }

    const modalElement = $("rightsModal");

    if (!modalElement) {
      console.error("rightsModal not found.");
      return;
    }

    bootstrap.Modal.getOrCreateInstance(modalElement).show();
  }

  // ============================================================
  // COPY RIGHTS
  // ============================================================

  function populateCopyRightsChoices() {
    if (!selectedUser) return;

    const sourceText = $("copyRightsSource");
    if (sourceText) {
      sourceText.textContent =
        `Source: ${(selectedUser.firstName || "").trim()} ${(selectedUser.lastName || "").trim()}`.trim();
    }

    const userSelect = $("copyRightsTargetUser");
    if (userSelect) {
      const targets = users.filter(
        (user) =>
          String(user._id) !== String(selectedUser._id) &&
          !isPrimaryAdmin(user),
      );
      userSelect.innerHTML = targets.length
        ? targets
            .map(
              (user) =>
                `<option value="${escapeHtml(user._id)}">${escapeHtml(`${user.firstName || ""} ${user.lastName || ""}`.trim() || user.email)} — ${escapeHtml(roleLabel(user))}</option>`,
            )
            .join("")
        : '<option value="">No editable users available</option>';
    }

    const roleSelect = $("copyRightsTargetRole");
    if (roleSelect) {
      const roles = [...new Set(availableRoles)];
      roleSelect.innerHTML = roles.length
        ? roles
            .map(
              (role) =>
                `<option value="${escapeHtml(role)}">All ${escapeHtml(role === "Admin" ? "Sub Admin" : role)} users</option>`,
            )
            .join("")
        : '<option value="">No roles available</option>';
    }
  }

  function syncCopyRightsTarget() {
    const isRole = $("copyRightsTargetType")?.value === "role";
    $("copyRightsUserWrap")?.classList.toggle("d-none", isRole);
    $("copyRightsRoleWrap")?.classList.toggle("d-none", !isRole);
  }

  $("openCopyRightsBtn")?.addEventListener("click", () => {
    if (!selectedUser) {
      errorAlert("Open the rights of a user first.");
      return;
    }
    populateCopyRightsChoices();
    syncCopyRightsTarget();
    bootstrap.Modal.getOrCreateInstance($("copyRightsModal")).show();
  });

  $("copyRightsTargetType")?.addEventListener("change", syncCopyRightsTarget);

  $("addRoleBtn")?.addEventListener("click", addCustomRole);
  $("rolePickerToggle")?.addEventListener("click", () => {
    const picker = $("rolePicker");
    if (!picker || $("role")?.disabled) return;
    const open = picker.classList.toggle("is-open");
    $("rolePickerToggle")?.setAttribute("aria-expanded", String(open));
  });
  $("rolePickerMenu")?.addEventListener("click", (event) => {
    const option = event.target.closest("[data-role]");
    const select = $("role");
    if (!option || !select || select.disabled) return;
    select.value = option.dataset.role;
    select.dispatchEvent(new Event("change", { bubbles: true }));
    $("rolePicker")?.classList.remove("is-open");
    $("rolePickerToggle")?.setAttribute("aria-expanded", "false");
    renderRolePicker();
  });
  document.addEventListener("click", (event) => {
    const picker = $("rolePicker");
    if (picker && !picker.contains(event.target)) {
      picker.classList.remove("is-open");
      $("rolePickerToggle")?.setAttribute("aria-expanded", "false");
    }
  });
  $("cancelRoleBtn")?.addEventListener("click", () => {
    $("customRoleName").value = "";
    $("customRoleControls").classList.add("d-none");
  });
  $("saveRoleBtn")?.addEventListener("click", () => {
    const input = $("customRoleName");
    const value = String(input?.value || "").trim();
    if (!/^[A-Za-z0-9 &_-]{2,49}$/.test(value)) {
      errorAlert("Use 2-49 letters, numbers, spaces, &, _ or -.");
      input?.focus();
      return;
    }
    createCustomRole(value);
  });
  $("customRoleName")?.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      $("saveRoleBtn")?.click();
    }
  });

  $("confirmCopyRightsBtn")?.addEventListener("click", async () => {
    if (!selectedUser) return;

    const targetType = $("copyRightsTargetType")?.value || "user";
    const payload = {
      sourceUserId: selectedUser._id,
      targetType,
      targetUserId:
        targetType === "user" ? $("copyRightsTargetUser")?.value : undefined,
      targetRole:
        targetType === "role" ? $("copyRightsTargetRole")?.value : undefined,
      copyAppRights: Boolean($("copyAppRights")?.checked),
      copyAccessRights: Boolean($("copyAccessRights")?.checked),
    };

    const button = $("confirmCopyRightsBtn");
    if (button) button.disabled = true;
    try {
      const result = await request("/admin/users/copy-rights", {
        method: "POST",
        body: JSON.stringify(payload),
      });
      bootstrap.Modal.getOrCreateInstance($("copyRightsModal")).hide();
      successAlert(result.message || "Rights copied successfully.");
      await loadUsers();
    } catch (error) {
      errorAlert(error.message);
    } finally {
      if (button) button.disabled = false;
    }
  });

  // ============================================================
  // COLLECT APP RIGHTS
  // ============================================================

  function collectAppRights() {
    const rights = {};

    document.querySelectorAll(".app-right-check").forEach((checkbox) => {
      rights[checkbox.value] = checkbox.checked;
    });

    return rights;
  }

  // ============================================================
  // COLLECT ACCESS RIGHTS
  // ============================================================

  function collectAccessRights() {
    const rights = {};

    document.querySelectorAll(".access-right-check").forEach((checkbox) => {
      rights[checkbox.value] = checkbox.checked;
    });

    return rights;
  }

  // ============================================================
  // OPEN EDIT USER
  // ============================================================

  function openEditUserModal(user) {
    selectedUser = user;

    const title = $("userModalTitle");
    const subtitle = $("userModalSubtitle");
    const footerTitle = $("userFooterTitle");
    const saveText = $("userSaveButtonText");
    const password = $("password");
    const passwordNote = $("passwordNote");
    if (title) title.textContent = "Edit Member";
    if (subtitle) subtitle.textContent = "Update member details, role and access";
    if (footerTitle) footerTitle.textContent = "Update Member";
    if (saveText) saveText.textContent = "Save Changes";
    if (password) password.placeholder = "Leave blank to keep unchanged";
    if (passwordNote) passwordNote.textContent = "If you leave the password blank, the current password will remain unchanged.";

    const form = $("userForm");

    if (!form) {
      console.error("userForm not found.");
      return;
    }

    form.reset();

    if ($("userId")) {
      $("userId").value = user._id || "";
    }

    if ($("name")) {
      $("name").value = user.firstName || "";
    }

    if ($("lastname")) {
      $("lastname").value = user.lastName || "";
    }

    if ($("mobile")) {
      $("mobile").value = user.phone || "";
    }

    if ($("email")) {
      $("email").value = user.email || "";
    }

    if ($("user_code")) {
      $("user_code").value = user.employerCode || "";
    }

    if ($("role")) {
      $("role").value = user.role || "Employee";

      // A created Admin can be returned to HR or Employee. The configured
      // primary Admin is the only account whose role stays locked.
      $("role").disabled = currentUserRole === "HR" || isPrimaryAdmin(user);
      renderRolePicker();
    }

    if ($("password")) {
      $("password").value = "";
    }

    // ========================================================
    // PROFILE IMAGE
    // ========================================================

    const preview = $("imagePreview");

    if (preview) {
      if (user.profileImage) {
        try {
          const backend = api.replace(/\/api\/?$/, "");

          preview.src = new URL(user.profileImage, `${backend}/`).href;
        } catch {
          preview.src = "../images/user-icon.jpg";
        }
      } else {
        preview.src = "../images/user-icon.jpg";
      }

      preview.onerror = function () {
        this.onerror = null;

        this.src = "../images/user-icon.jpg";
      };
    }

    const modal = $("addEditUserModal");

    if (!modal) {
      console.error("addEditUserModal not found.");
      return;
    }

    bootstrap.Modal.getOrCreateInstance(modal).show();
  }

  function openCreateUserModal() {
    selectedUser = null;
    const title = $("userModalTitle");
    const subtitle = $("userModalSubtitle");
    const footerTitle = $("userFooterTitle");
    const saveText = $("userSaveButtonText");
    const password = $("password");
    const passwordNote = $("passwordNote");
    if (title) title.textContent = "Add New Member";
    if (subtitle) subtitle.textContent = "Create a new team member and assign a role";
    if (footerTitle) footerTitle.textContent = "Add Member";
    if (saveText) saveText.textContent = "Save Member";
    if (password) password.placeholder = "Set a password (minimum 8 characters)";
    if (passwordNote) passwordNote.textContent = "Set a secure password of at least 8 characters for the new member.";
    const form = $("userForm");
    if (!form) return;
    form.reset();
    $("userId").value = "";
    if ($("role")) {
      $("role").value = "Employee";
      $("role").disabled = currentUserRole !== "Admin";
      renderRolePicker();
    }
    const preview = $("imagePreview");
    if (preview) preview.src = "../images/user-icon.jpg";
    bootstrap.Modal.getOrCreateInstance($("addEditUserModal")).show();
  }

  // ============================================================
  // TABLE CLICK
  // ============================================================

  $("usersTable")?.addEventListener("click", async (event) => {
    const element = event.target.closest("[data-action]");

    if (!element || element.disabled) {
      return;
    }

    const row = element.closest("tr");

    if (!row) return;

    const user = users.find(
      (item) => String(item._id) === String(row.dataset.id),
    );

    if (!user) return;

    const action = element.dataset.action;

    message();

    // ======================================================
    // APP RIGHTS
    // ======================================================

    if (action === "app") {
      openRightsModal(user, "app");
      return;
    }

    // ======================================================
    // ACCESS RIGHTS
    // ======================================================

    if (action === "access") {
      openRightsModal(user, "access");
      return;
    }

    // ======================================================
    // EDIT USER
    // ======================================================

    if (action === "edit") {
      openEditUserModal(user);
      return;
    }

    // ======================================================
    // STATUS TOGGLE
    // ======================================================

    if (action === "status") {
      const original = user.isActive;

      element.disabled = true;

      try {
        await updateUser(user._id, {
          isActive: element.checked,
        });

        successAlert(
          element.checked
            ? "User activated successfully."
            : "User deactivated successfully.",
        );
      } catch (error) {
        element.checked = original;

        errorAlert(error.message);
      } finally {
        element.disabled = false;
      }

      return;
    }

    // ======================================================
    // DELETE
    // ======================================================

    if (action === "delete") {
      let confirmed = false;

      if (window.Swal) {
        const result = await Swal.fire({
          icon: "warning",

          title: "Delete User?",

          text: `${user.firstName} ${user.lastName} will no longer be able to sign in.`,

          showCancelButton: true,

          confirmButtonText: "Delete",

          cancelButtonText: "Cancel",

          confirmButtonColor: "#dc3545",
        });

        confirmed = result.isConfirmed;
      } else {
        confirmed = confirm(`Delete ${user.firstName} ${user.lastName}?`);
      }

      if (!confirmed) {
        return;
      }

      element.disabled = true;

      try {
        await request(`/admin/users/${user._id}`, {
          method: "DELETE",
        });

        users = users.filter((item) => String(item._id) !== String(user._id));

        render();

        successAlert("User deleted successfully.");
      } catch (error) {
        errorAlert(error.message);
      } finally {
        element.disabled = false;
      }
    }
  });

  // ============================================================
  // SAVE RIGHTS
  // ============================================================

  $("saveRightsBtn")?.addEventListener("click", async () => {
    if (!selectedUser || !selectedEditor) {
      return;
    }

    const button = $("saveRightsBtn");

    if (button) {
      button.disabled = true;
    }

    try {
      let payload;

      // ======================================================
      // APP RIGHTS
      // ======================================================

      if (selectedEditor === "app") {
        payload = {
          appRights: collectAppRights(),
        };
      }

      // ======================================================
      // ACCESS RIGHTS
      // ======================================================
      else {
        payload = {
          accessRights: collectAccessRights(),
        };
      }

      await updateUser(selectedUser._id, payload);

      const modal = $("rightsModal");

      if (modal) {
        bootstrap.Modal.getOrCreateInstance(modal).hide();
      }

      successAlert(
        selectedEditor === "app"
          ? "App rights updated successfully."
          : "Access rights updated successfully.",
      );
    } catch (error) {
      errorAlert(error.message);
    } finally {
      if (button) {
        button.disabled = false;
      }
    }
  });

  // ============================================================
  // SELECT ALL APP RIGHTS
  // ============================================================

  $("selectAllAppsBtn")?.addEventListener("click", () => {
    document.querySelectorAll(".app-right-check").forEach((checkbox) => {
      if (!checkbox.disabled) {
        checkbox.checked = true;
      }
    });
  });

  // ============================================================
  // CLEAR ALL APP RIGHTS
  // ============================================================

  $("clearAllAppsBtn")?.addEventListener("click", () => {
    document.querySelectorAll(".app-right-check").forEach((checkbox) => {
      if (!checkbox.disabled) {
        checkbox.checked = false;
      }
    });
  });

  // ============================================================
  // EDIT USER FORM
  // ============================================================

  $("userForm")?.addEventListener("submit", async (event) => {
    event.preventDefault();

    const form = event.currentTarget;

    const button = form.querySelector('[type="submit"]');

    const userId = $("userId")?.value;

    if (button) {
      button.disabled = true;
    }

    const data = new FormData();

    // ======================================================
    // BASIC USER DATA
    // ======================================================

    if ($("name")) {
      data.append("firstName", $("name").value.trim());
    }

    if ($("lastname")) {
      data.append("lastName", $("lastname").value.trim());
    }

    if ($("mobile")) {
      data.append("phone", $("mobile").value.trim());
    }

    if ($("email")) {
      data.append("email", $("email").value.trim());
    }

    if ($("user_code")) {
      data.append("employerCode", $("user_code").value.trim());
    }

    // ======================================================
    // ROLE
    // ======================================================

    if (currentUserRole === "Admin" && $("role") && !$("role").disabled) {
      data.append("role", $("role").value);
    }

    // ======================================================
    // PASSWORD
    // ======================================================

    const password = $("password")?.value || "";

    if (password.trim()) {
      data.append("password", password);
    }

    // ======================================================
    // PROFILE IMAGE
    // ======================================================

    const imageInput = $("profileImage");

    const profileImage = imageInput?.files?.[0];

    if (profileImage) {
      data.append("profileImage", profileImage);
    }

    try {
      if (userId) {
        await updateUser(userId, data);
      } else {
        const passwordValue = $("password")?.value || "";
        if (passwordValue.trim().length < 8) {
          throw new Error(
            "New users need a password of at least 8 characters.",
          );
        }
        const result = await request("/admin/users", {
          method: "POST",
          body: data,
        });
        users.unshift(result.data);
        render();
      }

      const modal = $("addEditUserModal");

      if (modal) {
        bootstrap.Modal.getOrCreateInstance(modal).hide();
      }

      successAlert(
        userId ? "User updated successfully." : "User created successfully.",
      );
    } catch (error) {
      errorAlert(error.message);
    } finally {
      if (button) {
        button.disabled = false;
      }
    }
  });

  // ============================================================
  // PROFILE IMAGE PREVIEW
  // ============================================================

  $("profileImage")?.addEventListener("change", (event) => {
    const file = event.target.files?.[0];

    if (!file) {
      return;
    }

    const preview = $("imagePreview");

    if (!preview) {
      return;
    }

    const reader = new FileReader();

    reader.onload = () => {
      preview.src = reader.result;
    };

    reader.readAsDataURL(file);
  });

  $("addUserBtn")?.addEventListener("click", openCreateUserModal);
  document
    .querySelector("[data-users-add-trigger]")
    ?.addEventListener("click", openCreateUserModal);

  // ============================================================
  // SEARCH
  // ============================================================

  $("globalSearch")?.addEventListener("input", render);
  ["roleFilter", "statusFilter", "dateFilter"].forEach((id) =>
    $(id)?.addEventListener("change", () => {
      inactiveOnly = false;
      render();
    }),
  );

  // ============================================================
  // DEACTIVE USERS
  // ============================================================

  $("filterInactiveBtn")?.addEventListener("click", () => {
    inactiveOnly = true;

    render();
  });

  // ============================================================
  // ALL USERS
  // ============================================================

  $("showAllBtn")?.addEventListener("click", () => {
    inactiveOnly = false;

    render();
  });

  // ============================================================
  // EXPORT EXCEL
  // ============================================================

  $("exportExcelBtn")?.addEventListener("click", async () => {
    const button = $("exportExcelBtn");

    if (button) {
      button.disabled = true;
    }

    try {
      const query = $("globalSearch")?.value || "";

      const params = new URLSearchParams({
        q: query,

        inactive: String(inactiveOnly),
      });

      const response = await fetch(
        `${api}/admin/users-export?${params.toString()}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        },
      );

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));

        throw new Error(errorData.message || "Unable to export users.");
      }

      const blob = await response.blob();

      const url = URL.createObjectURL(blob);

      const anchor = document.createElement("a");

      anchor.href = url;

      anchor.download = "users.xlsx";

      document.body.appendChild(anchor);

      anchor.click();

      anchor.remove();

      setTimeout(() => URL.revokeObjectURL(url), 1000);
    } catch (error) {
      errorAlert(error.message);
    } finally {
      if (button) {
        button.disabled = false;
      }
    }
  });

  // ============================================================
  // PRINT USERS
  // ============================================================

  $("printCardBtn")?.addEventListener("click", () => {
    const list = filteredUsers();

    const popup = window.open("", "_blank");

    if (!popup) {
      errorAlert("Please allow pop-ups to print user cards.");

      return;
    }

    const cards = list
      .map(
        (user) => `
              <article>

                <h2>
                  ${escapeHtml(user.firstName)}
                  ${escapeHtml(user.lastName)}
                </h2>

                <p>
                  <strong>
                    Employee Code:
                  </strong>

                  ${escapeHtml(user.employerCode)}
                </p>

                <p>
                  <strong>
                    Role:
                  </strong>

                  ${escapeHtml(user.role)}
                </p>

                <p>
                  ${escapeHtml(user.email)}
                </p>

                <p>
                  ${escapeHtml(user.phone)}
                </p>

              </article>
            `,
      )
      .join("");

    popup.document.write(`
        <!DOCTYPE html>

        <html>

        <head>

          <title>
            User Cards
          </title>

          <style>

            body {
              font-family:
                Arial,
                sans-serif;

              display:
                flex;

              flex-wrap:
                wrap;

              gap:
                20px;

              padding:
                20px;
            }

            article {
              border:
                1px solid
                #aaa;

              border-radius:
                10px;

              padding:
                20px;

              width:
                280px;

              break-inside:
                avoid;
            }

            h2 {
              margin-top:
                0;
            }

            p {
              overflow-wrap:
                anywhere;
            }

          </style>

        </head>

        <body>

          ${cards}

        </body>

        </html>
      `);

    popup.document.close();

    popup.focus();

    popup.print();
  });

  // ============================================================
  // LOAD USERS
  // ============================================================

  async function loadUsers() {
    message();

    const table = $("usersTable");

    const tbody = table?.querySelector("tbody");

    try {
      const result = await request("/admin/users");

      currentUserId = String(result.currentUserId || "");

      users = Array.isArray(result.data) ? result.data : [];
      availableRoles =
        Array.isArray(result.roles) && result.roles.length
          ? result.roles
          : ["Employee", "HR", "Admin"];

      // ======================================================
      // FIND CURRENT USER
      // ======================================================

      const current = users.find(
        (user) => String(user._id) === String(currentUserId),
      );

      currentUserRole = current?.isAdministrator
        ? "Admin"
        : normalizeRole(result.currentUserRole || current?.role);

      populateRoleSelect();
      const roleFilter = $("roleFilter");
      if (roleFilter) {
        const selected = roleFilter.value;
        roleFilter.innerHTML =
          '<option value="">All Roles</option>' +
          availableRoles
            .map(
              (role) =>
                `<option value="${escapeHtml(role)}">${escapeHtml(role === "Admin" ? "Sub Admin" : role)}</option>`,
            )
            .join("");
        roleFilter.value = availableRoles.includes(selected) ? selected : "";
      }
      const addRoleButton = $("addRoleBtn");
      if (addRoleButton) {
        addRoleButton.classList.toggle("d-none", !isCurrentUserPrimaryAdmin());
      }

      if (current) {
        const sidebarName = $("sidebarUserName");

        if (sidebarName) {
          sidebarName.textContent = current.firstName || current.role;
        }

        const header = $("headerUserCode");

        if (header) {
          header.textContent = current.employerCode || current.role;
        }
      } else {
        const header = $("headerUserCode");

        if (header) {
          header.textContent = currentUserRole;
        }
      }

      render();
    } catch (error) {
      console.error("LOAD USERS ERROR:", error);

      if (tbody) {
        tbody.innerHTML = `
          <tr>
            <td
              colspan="10"
              class="text-center py-4 text-danger"
            >
              ${escapeHtml(error.message || "Users could not be loaded.")}
            </td>
          </tr>
        `;
      }

      const total = $("totalUsersCount");

      if (total) {
        total.textContent = "Total Users: —";
      }

      message(error.message);
    }
  }

  // ============================================================
  // START
  // ============================================================

  loadUsers();
});
