(() => {
  "use strict";
  if (new URLSearchParams(location.search).get("status") === "interested") return;
  const local = ["localhost", "127.0.0.1"].includes(location.hostname);
  const api = local ? "http://localhost:3000/api" : (localStorage.getItem("highCustomApiBase") || "https://high-custom-app.onrender.com/api");
  const token = localStorage.getItem("highCustomAdminToken");
  const notify = (message, bad = false) => window.toastr ? (bad ? toastr.error(message) : toastr.success(message)) : alert(message);
  async function update(id, payload) {
    const response = await fetch(`${api}/leads/update-lead/${id}`, { method:"PUT", headers:{Accept:"application/json","Content-Type":"application/json",Authorization:`Bearer ${token}`}, body:JSON.stringify(payload) });
    const data = await response.json().catch(() => ({}));
    if (!response.ok || data.success === false) throw new Error(data.message || "Unable to update lead.");
  }
  const idFor = row => row.querySelector("[data-edit], [data-delete]")?.dataset.edit || row.querySelector("[data-delete]")?.dataset.delete || row.querySelector("[data-lead-id]")?.dataset.leadId;
  function prepare() {
    const root = document.querySelector(".mlp");
    const table = root?.querySelector(".mlp-table");
    if (!table) return;
    table.querySelectorAll("thead tr").forEach(row => { if (row.cells[5]?.textContent.trim().toLowerCase() === "channel") row.cells[5].remove(); });
    table.querySelectorAll("tbody tr").forEach(row => {
      if (row.cells.length > 8 && row.cells[5]) row.cells[5].remove();
      const id = idFor(row);
      if (!id || row.dataset.inlineReady) return;
      row.dataset.inlineReady = "true";
      [[2,"email"],[3,"name"],[4,"company"]].forEach(([index, field]) => {
        const cell = row.cells[index];
        if (!cell) return;
        cell.classList.add("mlp-inline-edit");
        cell.dataset.field = field;
      });
      row.querySelector("[data-view]")?.remove();
      const actions = row.querySelector(".mlp-actions");
      if (actions && !actions.children.length) actions.closest("td")?.remove();
    });
    if (!root.querySelector(".mlp-edit-hint")) table.closest(".mlp-tablecard")?.insertAdjacentHTML("afterbegin", '<p class="mlp-edit-hint"><i class="fa-solid fa-pen-to-square"></i>Click Email, Name or Company to edit. Press Enter to save.</p>');
  }
  function edit(cell) {
    if (cell.querySelector("input")) return;
    const row = cell.closest("tr"), id = idFor(row), field = cell.dataset.field, old = cell.textContent.trim();
    if (!id || !field) return;
    const input = document.createElement("input");
    input.className = "mlp-inline-input";
    input.value = old === "—" ? "" : old;
    input.type = field === "email" ? "email" : "text";
    cell.classList.add("mlp-editing");
    cell.replaceChildren(input);
    input.focus(); input.select();
    let saving = false;
    const cancel = () => { if (!saving) { cell.textContent = old; cell.classList.remove("mlp-editing"); } };
    const save = async () => {
      if (saving) return;
      const value = input.value.trim();
      if (!value) { notify("This field cannot be empty.", true); input.focus(); return; }
      saving = true;
      try {
        const payload = field === "name" ? (() => { const [firstName, ...rest] = value.split(/\s+/); return {firstName, lastName:rest.join(" ")}; })() : {[field]:value};
        await update(id, payload);
        cell.textContent = value;
        cell.classList.remove("mlp-editing");
        notify("Lead updated successfully.");
      } catch (error) { cell.textContent = old; cell.classList.remove("mlp-editing"); notify(error.message, true); }
      saving = false;
    };
    input.addEventListener("keydown", event => { if (event.key === "Enter") { event.preventDefault(); save(); } if (event.key === "Escape") cancel(); });
    input.addEventListener("blur", () => { if (!saving && input.value.trim() !== old) save(); else if (!saving) cancel(); });
  }
  document.addEventListener("DOMContentLoaded", () => setTimeout(() => {
    const root = document.querySelector(".mlp");
    if (!root) return;
    prepare();
    new MutationObserver(prepare).observe(root, {childList:true, subtree:true});
    root.addEventListener("click", event => { const cell = event.target.closest(".mlp-inline-edit"); if (cell && !event.target.closest("input")) edit(cell); });
  }, 220));
})();
