(() => {
  "use strict";
  const start = () => {
    const root = document.querySelector(".mlp");
    const card = root?.querySelector(".mlp-date");
    if (!root || !card || card.dataset.dateReady) return;
    card.dataset.dateReady = "true";
    const title = card.querySelector("small"), value = card.querySelector("strong");
    const menu = document.createElement("div");
    menu.className = "mlp-date-menu";
    menu.innerHTML = '<button class="mlp-date-option active" type="button" data-range="today"><i class="fa-regular fa-calendar-day"></i>Today</button><button class="mlp-date-option" type="button" data-range="7days"><i class="fa-regular fa-calendar-week"></i>Last 7 Days</button><button class="mlp-date-option" type="button" data-range="30days"><i class="fa-regular fa-calendar-days"></i>Last 30 Days</button><button class="mlp-date-option" type="button" data-range="all"><i class="fa-solid fa-infinity"></i>All Time</button>';
    card.append(menu);
    const apply = range => {
      const now = new Date();
      let visible = 0;
      root.querySelectorAll("#mlpRows tr").forEach(row => {
        const text = row.cells?.[7]?.textContent || "";
        const itemDate = new Date(text);
        let show = true;
        if (range !== "all" && !Number.isNaN(itemDate.getTime())) {
          const diff = now - itemDate;
          show = range === "today" ? itemDate.toDateString() === now.toDateString() : range === "7days" ? diff >= 0 && diff <= 7 * 86400000 : diff >= 0 && diff <= 30 * 86400000;
        }
        row.hidden = !show;
        if (show && row.cells) visible += 1;
      });
      const labels = { today:"Today", "7days":"Last 7 Days", "30days":"Last 30 Days", all:"All Time" };
      title.textContent = labels[range];
      value.textContent = range === "today" ? new Intl.DateTimeFormat("en-GB", {day:"numeric",month:"short",year:"numeric"}).format(now) : range === "all" ? "All leads" : "Filtered leads";
      card.dataset.filtered = range === "all" ? "false" : "true";
      const info = root.querySelector("#mlpInfo");
      if (info) info.textContent = `Showing ${visible} ${range === "all" ? "leads" : "matching leads"}`;
    };
    card.addEventListener("click", event => {
      const option = event.target.closest("[data-range]");
      if (option) {
        const range = option.dataset.range;
        menu.querySelectorAll(".active").forEach(item => item.classList.remove("active"));
        option.classList.add("active");
        card.classList.remove("open");
        apply(range);
        return;
      }
      card.classList.toggle("open");
    });
    document.addEventListener("click", event => { if (!card.contains(event.target)) card.classList.remove("open"); });
    root.querySelector("#mlpPages")?.addEventListener("click", () => setTimeout(() => { const active = menu.querySelector(".active")?.dataset.range || "today"; apply(active); }, 0));
  };
  document.addEventListener("DOMContentLoaded", () => setTimeout(start, 180));
})();
