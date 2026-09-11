document.addEventListener("DOMContentLoaded", () => {
  "use strict";

  // ============================================================
  // HELPERS
  // ============================================================

  const $ = (id) => document.getElementById(id);

  const api =
    localStorage.getItem("highCustomApiBase") ||
    (["localhost", "127.0.0.1"].includes(location.hostname)
      ? "http://localhost:3000/api"
      : "https://high-custom-app.onrender.com/api");

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

  function isHR(user) {
    return user?.role === "HR";
  }

  function canCurrentUserManage(user) {
    if (!user || isSelf(user)) {
      return false;
    }

    // ADMIN
    if (currentUserRole === "Admin") {
      return user.role !== "Admin";
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

  // ============================================================
  // ROLE CLASS
  // ============================================================

  function roleClass(user) {
    if (isAdmin(user)) {
      return "role-admin";
    }

    if (isHR(user)) {
      return "role-hr";
    }

    return "role-employee";
  }

  // ============================================================
  // DATA SCOPE LABEL
  // ============================================================

  function scopeLabel(scope) {
    switch (scope) {
      case "all":
        return "All Company Data";

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

    return users.filter((user) => {
      if (inactiveOnly && user.isActive !== false) {
        return false;
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

        const deletable = canDelete(user);

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
                ${!manageable ? "disabled" : ""}
                title="${
                  self
                    ? "You cannot edit yourself here"
                    : !manageable
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
              ${escapeHtml(user.firstName)}
              ${escapeHtml(user.lastName)}

              ${
                self
                  ? `
                    <small class="text-muted">
                      (You)
                    </small>
                  `
                  : ""
              }
            </td>

            <td>
              ${escapeHtml(user.phone)}
            </td>

            <td>
              ${escapeHtml(user.email)}
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

                ${escapeHtml(user.role)}
              </span>
            </td>

            <td class="text-center">
              <button
                type="button"
                class="rights-edit-btn"
                data-action="app"
                ${!manageable ? "disabled" : ""}
                title="Edit App Rights"
              >
                <i class="fas fa-pen"></i>
              </button>
            </td>

            <td class="text-center">
              <button
                type="button"
                class="rights-edit-btn"
                data-action="access"
                ${!manageable ? "disabled" : ""}
                title="Edit Access Rights"
              >
                <i class="fas fa-pen"></i>
              </button>
            </td>

            <td class="text-center">
              <div
                class="
                  form-check
                  form-switch
                  d-flex
                  justify-content-center
                  m-0
                "
              >
                <input
                  type="checkbox"
                  class="form-check-input"
                  data-action="status"
                  ${user.isActive ? "checked" : ""}
                  ${!manageable ? "disabled" : ""}
                >
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

    applyAppRestrictions(user);
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

    const scope = $("modalDataScope");

    if (scope) {
      scope.value = user.dataScope || "own";

      scope.disabled = false;

      Array.from(scope.options).forEach((option) => {
        option.disabled = false;
      });
    }

    applyAccessRestrictions(user);
  }

  // ============================================================
  // ACCESS RESTRICTIONS
  // ============================================================

  function applyAccessRestrictions(user) {
    const checkboxes = document.querySelectorAll(".access-right-check");

    const scope = $("modalDataScope");

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

      // HR cannot give employee company-wide scope.
      if (scope) {
        Array.from(scope.options).forEach((option) => {
          if (option.value === "all") {
            option.disabled = true;
          }
        });

        if (scope.value === "all") {
          scope.value = "own";
        }
      }

      return;
    }

    // Everyone else blocked.
    checkboxes.forEach((checkbox) => {
      checkbox.disabled = true;
    });

    if (scope) {
      scope.disabled = true;
    }
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

      roleBadge.textContent = user.role;
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

      $("role").disabled = currentUserRole === "HR";
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
          preview.src = "/images/company-logo.png";
        }
      } else {
        preview.src = "/images/company-logo.png";
      }

      preview.onerror = function () {
        this.onerror = null;

        this.src = "/images/company-logo.png";
      };
    }

    const modal = $("addEditUserModal");

    if (!modal) {
      console.error("addEditUserModal not found.");
      return;
    }

    bootstrap.Modal.getOrCreateInstance(modal).show();
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
        const scope = $("modalDataScope");

        payload = {
          accessRights: collectAccessRights(),

          dataScope: scope ? scope.value : selectedUser.dataScope || "own",
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

    if (!userId) {
      errorAlert("User ID is missing.");

      return;
    }

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

    if (currentUserRole === "Admin" && $("role")) {
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
      await updateUser(userId, data);

      const modal = $("addEditUserModal");

      if (modal) {
        bootstrap.Modal.getOrCreateInstance(modal).hide();
      }

      successAlert("User updated successfully.");
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

  // ============================================================
  // SEARCH
  // ============================================================

  $("globalSearch")?.addEventListener("input", render);

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

      currentUserRole = result.currentUserRole || "Admin";

      users = Array.isArray(result.data) ? result.data : [];

      // ======================================================
      // FIND CURRENT USER
      // ======================================================

      const current = users.find(
        (user) => String(user._id) === String(currentUserId),
      );

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
