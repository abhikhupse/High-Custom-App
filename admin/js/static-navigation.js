(function () {
    'use strict';

    const normalize = (value = '') => String(value).replace(/\s+/g, ' ').trim();
    const normalizePath = (value = '') => {
        const cleaned = String(value).replace(/\/{2,}/g, '/').replace(/\/$/, '');
        return cleaned || '/';
    };

    // Resolve the real admin root from THIS script URL.
    // Examples:
    //   http://127.0.0.1:5500/admin/js/static-navigation.js -> /admin/
    //   http://127.0.0.1:5501/js/static-navigation.js       -> /
    // This keeps the same files working whether Live Server is started from
    // the repository root or directly from the admin folder.
    const currentScriptUrl = new URL(
        document.currentScript?.src || 'js/static-navigation.js',
        window.location.href
    );
    const adminBaseUrl = new URL('../', currentScriptUrl);
    const adminPath = (relativePath) => new URL(
        String(relativePath || '').replace(/^\/+/, ''),
        adminBaseUrl
    ).pathname;

    if (!document.getElementById('adminMobileResponsiveCss')) {
        const responsiveCss = document.createElement('link');
        responsiveCss.id = 'adminMobileResponsiveCss';
        responsiveCss.rel = 'stylesheet';
        responsiveCss.href = adminPath('css/admin-mobile-responsive.css');
        document.head.appendChild(responsiveCss);
    }

    const routes = {
        Dashboard: adminPath('index.html'),
        Master: adminPath('master/master-list.html'),
        Sequence: adminPath('master/master-list.html'),
        Link: adminPath('social/link-document.html'),
        Leads: adminPath('Leads/index.html'),
        'Social Links': adminPath('social/index.html'),
        'Tracking Report': adminPath('reports/campaign.html'),
        'Users Master': adminPath('master/userMasterList.html'),
        'Users Rights': adminPath('users/index.html'),
        'All Tracking': adminPath('master/UserSequenceTable.html')
    };

    const currentPath = normalizePath(window.location.pathname);

    // Keep Admin navigation in the same flow as the User Panel:
    // Admin → Social Links, Link, Sequence, Tracking Report; Leads is standalone.
    const organiseAdminFlow = () => {
        const submenu = document.getElementById('submenu-admin');
        const adminParent = document.getElementById('adminParentLink');
        if (!submenu || !adminParent) return;

        const linkByName = (name) => [...submenu.querySelectorAll('.nav-link')]
            .find((link) => normalize(link.textContent) === name);

        const master = linkByName('Master');
        if (master) {
            master.innerHTML = '<i class="fas fa-envelope"></i><span class="menu-text">Sequence</span>';
        }

        const sequence = linkByName('Sequence');
        const social = linkByName('Social Links');
        const link = linkByName('Link');
        const tracking = linkByName('Tracking Report');
        const leads = linkByName('Leads');

        [social, link, sequence, tracking]
            .filter(Boolean)
            .forEach((item) => {
                const navItem = item.closest('.nav-item');
                if (navItem) submenu.append(navItem);
            });

        if (leads) {
            const leadsItem = leads.closest('.nav-item');
            const adminItem = adminParent.closest('.nav-item');
            if (leadsItem && adminItem) {
                leadsItem.setAttribute('role', 'none');
                leads.innerHTML = '<i class="fas fa-chart-line"></i><span class="menu-text">Leads</span>';
                adminItem.after(leadsItem);
            }
        }
    };

    const prepareMobileTableCards = () => {
        document.querySelectorAll('table').forEach((table) => {
            const headers = [...table.querySelectorAll('thead th')].map((header) =>
                normalize(header.textContent) || 'Details'
            );
            if (!headers.length) return;

            table.classList.add('admin-card-table');
            table.querySelectorAll('tbody tr').forEach((row) => {
                [...row.children].forEach((cell, index) => {
                    if (cell.tagName === 'TD' && !cell.hasAttribute('colspan')) {
                        cell.dataset.mobileLabel = headers[index] || 'Details';
                    }
                });
            });
        });
    };

    const applyRoutesAndActiveState = () => {
        document.querySelectorAll('.sidebar .nav-link').forEach((link) => {
            const label = normalize(link.textContent);
            const destination = routes[label];
            if (!destination) return;

            link.setAttribute('href', destination);
            link.classList.remove('active');

            if (currentPath.toLowerCase() !== normalizePath(destination).toLowerCase()) return;

            link.classList.add('active');
            const submenu = link.closest('.sub-menu');
            if (!submenu) return;

            submenu.classList.add('open');
            const parent = submenu.parentElement?.querySelector(':scope > .nav-link');
            parent?.classList.add('active-indicator');
            parent?.setAttribute('aria-expanded', 'true');
            parent?.querySelector('.arrow')?.classList.add('open');
        });
    };

    organiseAdminFlow();
    applyRoutesAndActiveState();
    prepareMobileTableCards();

    document.addEventListener('DOMContentLoaded', () => {
        organiseAdminFlow();
        applyRoutesAndActiveState();
        prepareMobileTableCards();

        if (document.body) {
            new MutationObserver(prepareMobileTableCards).observe(document.body, {
                childList: true,
                subtree: true
            });
        }
    });
})();
