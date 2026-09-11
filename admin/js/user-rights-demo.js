document.addEventListener('DOMContentLoaded', function () {
    const rows = document.querySelectorAll('#usersTable tbody tr');
    const modalElement = document.getElementById('rightsModal');
    if (!rows.length || !modalElement || !window.bootstrap) return;

    const modal = bootstrap.Modal.getOrCreateInstance(modalElement);
    const appEditor = document.getElementById('appRightsEditor');
    const accessEditor = document.getElementById('accessRightsEditor');
    const userName = document.getElementById('rightsUserName');
    const accessSelect = document.getElementById('modalAccessRight');
    let activeButton = null;

    rows.forEach(function (row, rowIndex) {
        const name = row.cells[2].textContent.trim();
        const appSelect = row.querySelector('.app-right-select');
        const accessRightSelect = row.querySelector('.access-right-select');
        const statusBadge = row.cells[8].querySelector('.badge');

        if (appSelect) {
            const selected = appSelect.value === 'All Applications'
                ? ['Dashboard', 'Leads', 'Social Links', 'Tracking Reports', 'User Management', 'Sequences']
                : [appSelect.value];
            const button = makeEditButton('app', name, selected.join(','));
            appSelect.replaceWith(button);
        }

        if (accessRightSelect) {
            const button = makeEditButton('access', name, accessRightSelect.value);
            accessRightSelect.replaceWith(button);
        }

        if (statusBadge) {
            const wrapper = document.createElement('div');
            wrapper.className = 'form-check form-switch d-flex justify-content-center m-0';
            wrapper.innerHTML = '<input class="form-check-input user-status-switch" type="checkbox" aria-label="Toggle status for ' + name + '" ' + (statusBadge.textContent.trim() === 'Active' ? 'checked' : '') + '>';
            statusBadge.replaceWith(wrapper);
        }

        row.dataset.userIndex = rowIndex;
    });

    function makeEditButton(type, name, value) {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'rights-edit-btn';
        button.dataset.rightType = type;
        button.dataset.userName = name;
        button.dataset.value = value;
        button.title = (type === 'app' ? 'App Rights: ' : 'Access Right: ') + value;
        button.setAttribute('aria-label', 'Edit ' + (type === 'app' ? 'app' : 'access') + ' rights for ' + name);
        button.innerHTML = '<i class="fas fa-pen"></i>';
        button.addEventListener('click', openRightsModal);
        return button;
    }

    function openRightsModal(event) {
        activeButton = event.currentTarget;
        const isApp = activeButton.dataset.rightType === 'app';
        userName.textContent = activeButton.dataset.userName;
        document.getElementById('rightsModalTitle').textContent = isApp ? 'Select App Rights' : 'Select Access Right';
        appEditor.classList.toggle('d-none', !isApp);
        accessEditor.classList.toggle('d-none', isApp);

        if (isApp) {
            const selected = activeButton.dataset.value.split(',').filter(Boolean);
            document.querySelectorAll('.app-right-check').forEach(function (checkbox) {
                checkbox.checked = selected.includes(checkbox.value);
            });
        } else {
            accessSelect.value = activeButton.dataset.value;
        }

        modal.show();
    }

    document.getElementById('saveRightsBtn').addEventListener('click', function () {
        if (!activeButton) return;

        if (activeButton.dataset.rightType === 'app') {
            const selected = Array.from(document.querySelectorAll('.app-right-check:checked')).map(function (checkbox) {
                return checkbox.value;
            });
            activeButton.dataset.value = selected.join(',');
            activeButton.title = 'App Rights: ' + (selected.length ? selected.join(', ') : 'None');
        } else {
            activeButton.dataset.value = accessSelect.value;
            activeButton.title = 'Access Right: ' + accessSelect.value;
        }

        modal.hide();
    });
});
