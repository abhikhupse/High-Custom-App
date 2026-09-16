(() => {
  "use strict";

  if (new URLSearchParams(location.search).get("status") === "interested") return;

  const local = ["localhost", "127.0.0.1"].includes(location.hostname);
  const api = local ? "http://localhost:3000/api" : (localStorage.getItem("highCustomApiBase") || "https://high-custom-app.onrender.com/api");
  const token = localStorage.getItem("highCustomAdminToken");
  const selected = new Set();
  const message = (text, error = false) => window.toastr ? (error ? toastr.error(text) : toastr.success(text)) : alert(text);

  function table() { return document.querySelector(".mlp-table"); }
  function selectedIds() { return [...selected]; }

  function syncToolbar() {
    const root = document.querySelector(".mlp");
    if (!root) return;
    let toolbar = root.querySelector("#mlpBulkActions");
    if (!toolbar) {
      root.querySelector(".mlp-tools-right")?.insertAdjacentHTML("afterbegin", '<div class="mlp-bulk-actions" id="mlpBulkActions" hidden><span><b id="mlpSelectedCount">0</b> selected</span><button type="button" class="mlp-btn mlp-bulk-delete" data-bulk-delete><i class="fa-solid fa-trash"></i>Delete selected</button></div>');
      toolbar = root.querySelector("#mlpBulkActions");
    }
    const count = selected.size;
    toolbar.hidden = count === 0;
    toolbar.querySelector("#mlpSelectedCount").textContent = count;
  }

  function syncHeader() {
    const currentTable = table();
    if (!currentTable) return;
    const boxes = [...currentTable.querySelectorAll("tbody [data-lead-id]")];
    const all = currentTable.querySelector("#mlpSelectAll");
    if (!all) return;
    const checked = boxes.filter(box => box.checked).length;
    all.checked = boxes.length > 0 && checked === boxes.length;
    all.indeterminate = checked > 0 && checked < boxes.length;
  }

  function prepare() {
    const currentTable = table();
    if (!currentTable) return;
    const header = currentTable.querySelector("thead tr");
    if (!header) return;
    const actionHeader = [...header.cells].find(cell => cell.textContent.trim().toLowerCase() === "actions");
    actionHeader?.remove();
    if (!header.querySelector("#mlpSelectAll")) {
      header.insertAdjacentHTML("afterbegin", '<th class="mlp-select-cell"><input id="mlpSelectAll" type="checkbox" aria-label="Select all leads"></th>');
    }
    currentTable.querySelectorAll("tbody tr").forEach(row => {
      const actionCell = row.querySelector(".mlp-actions")?.closest("td");
      const id = actionCell?.querySelector("[data-delete]")?.dataset.delete || row.querySelector("[data-lead-id]")?.dataset.leadId;
      actionCell?.remove();
      if (!id || row.querySelector("[data-lead-id]")) return;
      row.insertAdjacentHTML("afterbegin", `<td class="mlp-select-cell"><input type="checkbox" data-lead-id="${String(id).replace(/&/g, "&amp;").replace(/"/g, "&quot;")}" aria-label="Select lead"></td>`);
      const checkbox = row.querySelector("[data-lead-id]");
      checkbox.checked = selected.has(String(id));
    });
    syncHeader();
    syncToolbar();
  }

  async function bulkDelete() {
    const ids = selectedIds();
    if (!ids.length) return;
    if (!confirm(`Delete ${ids.length} selected lead${ids.length === 1 ? "" : "s"}? This cannot be undone.`)) return;
    try {
      await Promise.all(ids.map(id => fetch(`${api}/leads/delete-lead/${encodeURIComponent(id)}`, { method: "DELETE", headers: { Accept: "application/json", Authorization: `Bearer ${token}` } }).then(async response => {
        const payload = await response.json().catch(() => ({}));
        if (!response.ok || payload.success === false) throw new Error(payload.message || "Unable to delete selected leads.");
      })));
      selected.clear();
      message(`${ids.length} lead${ids.length === 1 ? "" : "s"} deleted.`);
      location.reload();
    } catch (error) {
      message(error.message || "Unable to delete selected leads.", true);
    }
  }

  document.addEventListener("DOMContentLoaded", () => setTimeout(() => {
    const root = document.querySelector(".mlp");
    if (!root || !token) return;
    prepare();
    new MutationObserver(prepare).observe(root, { childList: true, subtree: true });
    root.addEventListener("change", event => {
      const checkbox = event.target.closest("[data-lead-id], #mlpSelectAll");
      if (!checkbox) return;
      if (checkbox.id === "mlpSelectAll") {
        root.querySelectorAll("tbody [data-lead-id]").forEach(box => {
          box.checked = checkbox.checked;
          if (box.checked) selected.add(String(box.dataset.leadId)); else selected.delete(String(box.dataset.leadId));
        });
      } else if (checkbox.checked) {
        selected.add(String(checkbox.dataset.leadId));
      } else {
        selected.delete(String(checkbox.dataset.leadId));
      }
      syncHeader();
      syncToolbar();
    });
    root.addEventListener("click", event => {
      if (event.target.closest("[data-bulk-delete]")) bulkDelete();
    });
  }, 320));
})();
