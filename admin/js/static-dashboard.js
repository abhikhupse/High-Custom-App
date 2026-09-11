(function () {
    const isLocal = ['localhost', '127.0.0.1'].includes(window.location.hostname);
    const apiBase = localStorage.getItem('highCustomApiBase') ||
        (isLocal ? 'http://localhost:3000/api' : 'https://high-custom-app.onrender.com/api');
    const tokenKey = 'highCustomAdminToken';
    // Admin opens on the company-wide, all-time view. Date presets narrow it
    // only when the administrator explicitly selects one.
    let dateFilter = 'all';

    function setText(id, value) {
        const element = document.getElementById(id);
        if (element) element.textContent = Number(value || 0).toLocaleString();
    }

    function dateParameters() {
        if (dateFilter === 'all') return {};
        const now = new Date();
        const start = new Date(now);
        const end = new Date(now);
        if (dateFilter === 'weekly') start.setDate(now.getDate() - 6);
        if (dateFilter === 'monthly') start.setDate(1);
        if (dateFilter === 'yearly') start.setMonth(0, 1);
        if (dateFilter === 'custom') {
            return { startDate: document.getElementById('startDate')?.value || '', endDate: document.getElementById('endDate')?.value || '' };
        }
        return { startDate: start.toISOString().slice(0, 10), endDate: end.toISOString().slice(0, 10) };
    }

    function parameters() {
        const userId = document.getElementById('userFilter')?.value || '';
        return new URLSearchParams({ ...dateParameters(), ...(userId && { userId }) });
    }

    function updateCharts(charts, stats) {
        if (typeof renderCampaignChart === 'function') {
            renderCampaignChart({ pending: stats.pending, sent: stats.sent, seen: stats.opened, fail: stats.failed, interested: stats.interested, not_interested: stats.notInterested, total_mail: stats.totalMails });
        }
        if (typeof renderPlatformChart === 'function') {
            renderPlatformChart({ labels: (charts.platforms || []).map((item) => item.label), series: (charts.platforms || []).map((item) => item.value), total: (charts.platforms || []).reduce((sum, item) => sum + item.value, 0) });
        }
        if (typeof renderButtonChart === 'function') {
            renderButtonChart({ labels: (charts.buttons || []).map((item) => item.label), series: (charts.buttons || []).map((item) => item.value), total: (charts.buttons || []).reduce((sum, item) => sum + item.value, 0) });
        }
    }

    function updateUsers(users) {
        const select = document.getElementById('userFilter');
        if (!select) return;
        const current = select.value;
        select.innerHTML = '<option value="">All Users</option>';
        users.forEach((user) => {
            const option = document.createElement('option');
            option.value = user.id;
            // Keep the native select list easy to scan. The email remains
            // available as a tooltip instead of making every row too long.
            const name = user.name || 'Unnamed user';
            const code = user.employerCode ? ` · ${user.employerCode}` : '';
            option.textContent = `${name}${code}`;
            option.title = user.email || name;
            select.appendChild(option);
        });
        select.value = current;
    }

    async function loadDashboard() {
        const token = localStorage.getItem(tokenKey);
        if (!token) return window.location.replace('admin-login.html');
        try {
            const response = await fetch(`${apiBase}/admin/dashboard?${parameters()}`, { headers: { Accept: 'application/json', Authorization: `Bearer ${token}` } });
            const payload = await response.json().catch(() => ({}));
            if (response.status === 401 || response.status === 403) {
                localStorage.removeItem(tokenKey);
                return window.location.replace('admin-login.html?reason=access');
            }
            if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to load dashboard.');
            updateUsers(payload.users || []);
            const stats = payload.stats || {};
            setText('totalLeads', stats.totalLeads); setText('totalMails', stats.totalMails); setText('todayLeads', stats.todayLeads);
            setText('pending', stats.pending); setText('sent', stats.sent); setText('seen', stats.opened); setText('failed', stats.failed);
            setText('interested', stats.interested); setText('notInterested', stats.notInterested); setText('qrScans', stats.qrScans);
            updateCharts(payload.charts || {}, stats);
            const adminCode = document.querySelector('.hc-user-code strong');
            if (adminCode) adminCode.textContent = 'LIVE ADMIN';
        } catch (error) {
            if (window.toastr) toastr.error(error.message || 'Unable to connect to the dashboard.');
            else console.error(error);
        }
    }

    function setPreset(filter) {
        dateFilter = filter;
        const label = document.getElementById('currentFilterLabel');
        if (label) label.textContent = filter.charAt(0).toUpperCase() + filter.slice(1);
        loadDashboard();
    }

    function attachEvents() {
        document.getElementById('userFilter')?.addEventListener('change', loadDashboard);
        document.querySelectorAll('.date-preset').forEach((item) => item.addEventListener('click', (event) => { event.preventDefault(); setPreset(item.dataset.filter || 'today'); }));
        document.getElementById('applyCustomFilter')?.addEventListener('click', (event) => { event.preventDefault(); setPreset('custom'); });
        document.getElementById('logoutBtn')?.addEventListener('click', (event) => { event.preventDefault(); localStorage.removeItem(tokenKey); window.location.replace('admin-login.html'); }, true);
    }

    window.HighCustomAdminDashboard = { refresh: loadDashboard };
    window.refreshDashboard = loadDashboard;
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', () => { attachEvents(); loadDashboard(); });
    else { attachEvents(); loadDashboard(); }
})();
