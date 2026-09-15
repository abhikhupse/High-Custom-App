(() => {
  "use strict";
  const init = () => {
    const root = document.querySelector(".mlp"), menu = root?.querySelector(".mlp-date-menu");
    if (!root || !menu || menu.dataset.customReady) return;
    menu.dataset.customReady = "true";
    menu.insertAdjacentHTML("beforeend", '<button class="mlp-date-option custom-option" type="button" data-custom><i class="fa-regular fa-calendar-plus"></i>Select Custom</button><div class="mlp-custom-range"><input type="date" aria-label="Start date"><input type="date" aria-label="End date"><button type="button">Apply custom range</button></div>');
    const range = menu.querySelector(".mlp-custom-range"), [start, end] = range.querySelectorAll("input"), applyButton = range.querySelector("button"), card = root.querySelector(".mlp-date");
    menu.addEventListener("click", event => {
      if (event.target.closest("[data-custom]")) { event.stopPropagation(); range.classList.toggle("show"); return; }
      if (!event.target.closest(".mlp-date-option")) event.stopPropagation();
    });
    applyButton.addEventListener("click", event => {
      event.stopPropagation();
      if (!start.value || !end.value) { window.toastr?.warning("Select both start and end dates."); return; }
      if (start.value > end.value) { window.toastr?.warning("Start date cannot be after end date."); return; }
      let visible = 0;
      const from = new Date(`${start.value}T00:00:00`), to = new Date(`${end.value}T23:59:59`);
      root.querySelectorAll("#mlpRows tr").forEach(row => {
        const itemDate = new Date(row.cells?.[7]?.textContent || "");
        const show = !Number.isNaN(itemDate.getTime()) && itemDate >= from && itemDate <= to;
        row.hidden = !show;
        if (show && row.cells) visible += 1;
      });
      card.querySelector("small").textContent = "Custom Range";
      card.querySelector("strong").textContent = `${start.value} – ${end.value}`;
      card.classList.remove("open");
      card.dataset.filtered = "true";
      const info = root.querySelector("#mlpInfo");
      if (info) info.textContent = `Showing ${visible} matching leads`;
    });
  };
  document.addEventListener("DOMContentLoaded", () => setTimeout(init, 230));
})();
