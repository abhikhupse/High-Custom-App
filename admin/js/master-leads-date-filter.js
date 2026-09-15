(() => {
  "use strict";
  const enhance = () => {
    const root = document.querySelector(".mlp");
    const filterButton = root?.querySelector("[data-filter]");
    if (!root || !filterButton || root.dataset.dateFilterReady) return;
    root.dataset.dateFilterReady = "true";
    const holder = document.createElement("label");
    holder.className = "mlp-date-filter";
    holder.innerHTML = '<i class="fa-regular fa-calendar-days"></i><select aria-label="Filter leads by date"><option value="">Date Filter</option><option value="today">Today</option><option value="7days">Last 7 Days</option><option value="30days">Last 30 Days</option></select>';
    filterButton.replaceWith(holder);
    const select = holder.querySelector("select");
    const apply = () => {
      const mode = select.value;
      const now = new Date();
      const body = root.querySelector("#mlpRows");
      [...body.querySelectorAll("tr")].forEach(row => {
        const text = row.cells?.[7]?.textContent || "";
        const rowDate = new Date(text);
        let visible = true;
        if (mode && !Number.isNaN(rowDate.getTime())) {
          const diff = now - rowDate;
          visible = mode === "today"
            ? rowDate.toDateString() === now.toDateString()
            : mode === "7days" ? diff <= 7 * 86400000 : diff <= 30 * 86400000;
        }
        row.hidden = !visible;
      });
      const info = root.querySelector("#mlpInfo");
      if (info && mode) info.dataset.dateLabel = select.options[select.selectedIndex].text;
      if (info && !mode) delete info.dataset.dateLabel;
    };
    select.addEventListener("change", apply);
    root.querySelector("[data-reset]")?.addEventListener("click", () => { select.value = ""; setTimeout(apply, 0); });
    root.querySelector("#mlpPages")?.addEventListener("click", () => setTimeout(apply, 0));
  };
  document.addEventListener("DOMContentLoaded", () => setTimeout(enhance, 170));
})();
