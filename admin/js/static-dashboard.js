(function () {
  const isLocal = ["localhost", "127.0.0.1"].includes(window.location.hostname);
  const apiBase = isLocal
    ? "http://localhost:3000/api"
    : localStorage.getItem("highCustomApiBase") ||
      "https://high-custom-app.onrender.com/api";
  const tokenKey = "highCustomAdminToken";
  // Admin opens on the company-wide, all-time view. Date presets narrow it
  // only when the administrator explicitly selects one.
  let dateFilter = "all";

  function setText(id, value) {
    const element = document.getElementById(id);
    if (element) element.textContent = Number(value || 0).toLocaleString();
  }

  function setDashboardState(message, isError = false) {
    const state = document.getElementById("dashboardDataState");
    if (!state) return;
    state.textContent = message || "";
    state.classList.toggle("is-error", Boolean(isError));
    state.hidden = !message;
  }

  function setLoading(isLoading) {
    document
      .querySelector(".dashboard-stats")
      ?.classList.toggle("is-loading", Boolean(isLoading));
  }

  function displayName(user) {
    return (
      [user?.firstName, user?.lastName].filter(Boolean).join(" ") ||
      user?.email ||
      "Profile unavailable"
    );
  }

  function displayRole(user) {
    return user?.role === "User" ? "Admin" : user?.role || "Admin";
  }

  async function loadProfile(token) {
    const response = await fetch(`${apiBase}/user/profile`, {
      headers: { Accept: "application/json", Authorization: `Bearer ${token}` },
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok || !payload.success || !payload.user)
      throw new Error(payload.message || "Profile unavailable");
    const user = payload.user;
    const name = displayName(user);
    const initials =
      name
        .split(/\s+/)
        .filter(Boolean)
        .slice(0, 2)
        .map((part) => part[0])
        .join("")
        .toUpperCase() || "A";
    document
      .querySelectorAll("[data-admin-profile-name]")
      .forEach((element) => (element.textContent = name));
    document
      .querySelectorAll("[data-admin-profile-role]")
      .forEach((element) => (element.textContent = displayRole(user)));
    document
      .querySelectorAll("[data-admin-profile-initials]")
      .forEach((element) => (element.textContent = initials));
    const image = document.querySelector("[data-admin-profile-image]");
    if (image && user.profileImage) {
      image.src = /^https?:\/\//i.test(user.profileImage)
        ? user.profileImage
        : `${apiBase.replace("/api", "")}${user.profileImage}`;
      image.hidden = false;
      image.onerror = () => {
        image.hidden = true;
      };
    }
  }

  function dateParameters() {
    if (dateFilter === "all") return {};
    const now = new Date();
    const start = new Date(now);
    const end = new Date(now);
    if (dateFilter === "weekly") start.setDate(now.getDate() - 6);
    if (dateFilter === "monthly") start.setDate(1);
    if (dateFilter === "yearly") start.setMonth(0, 1);
    if (dateFilter === "custom") {
      return {
        startDate: document.getElementById("startDate")?.value || "",
        endDate: document.getElementById("endDate")?.value || "",
      };
    }
    return {
      startDate: start.toISOString().slice(0, 10),
      endDate: end.toISOString().slice(0, 10),
    };
  }

  function parameters() {
    const userId = document.getElementById("userFilter")?.value || "";
    return new URLSearchParams({
      ...dateParameters(),
      ...(userId && { userId }),
    });
  }

  function updateCharts(charts, stats) {
    if (typeof renderCampaignChart === "function") {
      renderCampaignChart({
        pending: stats.pending,
        sent: stats.sent,
        seen: stats.opened,
        fail: stats.failed,
        interested: stats.interested,
        not_interested: stats.notInterested,
        total_mail: stats.totalMails,
      });
    }
    if (typeof renderPlatformChart === "function") {
      renderPlatformChart({
        labels: (charts.platforms || []).map((item) => item.label),
        series: (charts.platforms || []).map((item) => item.value),
        total: (charts.platforms || []).reduce(
          (sum, item) => sum + item.value,
          0,
        ),
      });
    }
    if (typeof renderButtonChart === "function") {
      renderButtonChart({
        labels: (charts.buttons || []).map((item) => item.label),
        series: (charts.buttons || []).map((item) => item.value),
        total: (charts.buttons || []).reduce(
          (sum, item) => sum + item.value,
          0,
        ),
      });
    }
  }

  function updateUsers(users) {
    const select = document.getElementById("userFilter");
    if (!select) return;
    const current = select.value;
    select.innerHTML = '<option value="">All Users</option>';
    users.forEach((user) => {
      const option = document.createElement("option");
      option.value = user.id;
      // Keep the native select list easy to scan. The email remains
      // available as a tooltip instead of making every row too long.
      const name = user.name || "Unnamed user";
      const code = user.employerCode ? ` · ${user.employerCode}` : "";
      option.textContent = `${name}${code}`;
      option.title = user.email || name;
      select.appendChild(option);
    });
    select.value = current;
  }

  async function loadDashboard() {
    const token = localStorage.getItem(tokenKey);
    if (!token) return window.location.replace("admin-login.html");
    setLoading(true);
    setDashboardState("");
    try {
      const response = await fetch(
        `${apiBase}/admin/dashboard?${parameters()}`,
        {
          headers: {
            Accept: "application/json",
            Authorization: `Bearer ${token}`,
          },
        },
      );
      const payload = await response.json().catch(() => ({}));
      if (response.status === 401 || response.status === 403) {
        localStorage.removeItem(tokenKey);
        return window.location.replace("admin-login.html?reason=access");
      }
      if (!response.ok || !payload.success)
        throw new Error(payload.message || "Unable to load dashboard.");
      updateUsers(payload.users || []);
      const stats = payload.stats || {};
      setText("totalLeads", stats.totalLeads);
      setText("totalMails", stats.totalMails);
      setText("todayLeads", stats.todayLeads);
      setText("pending", stats.pending);
      setText("sent", stats.sent);
      setText("seen", stats.opened);
      setText("failed", stats.failed);
      setText("interested", stats.interested);
      setText("clicked", stats.clicked);
      setText("replied", stats.replied);
      setText("qrScans", stats.qrScans);
      updateCharts(payload.charts || {}, stats);
      setDashboardState("");
      const adminCode = document.querySelector(".hc-user-code strong");
      if (adminCode) adminCode.textContent = "LIVE ADMIN";
    } catch (error) {
      setDashboardState("Unable to load dashboard data. Please retry.", true);
      if (window.toastr)
        toastr.error(error.message || "Unable to connect to the dashboard.");
      else console.error(error);
    } finally {
      setLoading(false);
    }
  }

  function setPreset(filter) {
    dateFilter = filter;
    const label = document.getElementById("currentFilterLabel");
    if (label)
      label.textContent = filter.charAt(0).toUpperCase() + filter.slice(1);
    loadDashboard();
  }

  function attachEvents() {
    document
      .getElementById("userFilter")
      ?.addEventListener("change", loadDashboard);
    document.querySelectorAll(".date-preset").forEach((item) =>
      item.addEventListener("click", (event) => {
        event.preventDefault();
        setPreset(item.dataset.filter || "today");
      }),
    );
    document
      .getElementById("applyCustomFilter")
      ?.addEventListener("click", (event) => {
        event.preventDefault();
        setPreset("custom");
      });
    document.getElementById("logoutBtn")?.addEventListener(
      "click",
      (event) => {
        event.preventDefault();
        localStorage.removeItem(tokenKey);
        window.location.replace("admin-login.html");
      },
      true,
    );
  }

  window.HighCustomAdminDashboard = { refresh: loadDashboard };
  window.refreshDashboard = loadDashboard;
  if (document.readyState === "loading")
    document.addEventListener("DOMContentLoaded", () => {
      attachEvents();
      const token = localStorage.getItem(tokenKey);
      if (token) loadProfile(token).catch(() => {});
      loadDashboard();
    });
  else {
    attachEvents();
    const token = localStorage.getItem(tokenKey);
    if (token) loadProfile(token).catch(() => {});
    loadDashboard();
  }
})();
