(() => {
  "use strict";
  const enhance = () => {
    const select = document.querySelector("#mlpType");
    if (!select || select.dataset.enhanced) return;
    select.dataset.enhanced = "true";
    const picker = document.createElement("div");
    picker.className = "mlp-type-picker";
    picker.innerHTML = '<button type="button" class="mlp-type-trigger" aria-expanded="false">Select business type</button><div class="mlp-type-menu"></div>';
    select.after(picker);
    select.hidden = true;
    const trigger = picker.querySelector(".mlp-type-trigger");
    const menu = picker.querySelector(".mlp-type-menu");
    const populate = () => {
      const options = [...select.options].filter(option => option.value);
      menu.innerHTML = options.length ? options.map(option => `<button type="button" class="mlp-type-option ${select.value === option.value ? "selected" : ""}" data-value="${option.value}">${option.textContent}</button>`).join("") : '<div class="mlp-type-empty">No business types available</div>';
    };
    populate();
    new MutationObserver(populate).observe(select, { childList: true });
    trigger.addEventListener("click", () => { picker.classList.toggle("open"); trigger.setAttribute("aria-expanded", String(picker.classList.contains("open"))); });
    menu.addEventListener("click", event => { const option = event.target.closest("[data-value]"); if (!option) return; select.value = option.dataset.value; select.dispatchEvent(new Event("change", { bubbles: true })); trigger.textContent = option.textContent; populate(); picker.classList.remove("open"); trigger.setAttribute("aria-expanded", "false"); });
    document.addEventListener("click", event => { if (!picker.contains(event.target)) { picker.classList.remove("open"); trigger.setAttribute("aria-expanded", "false"); } });
    select.closest("form")?.addEventListener("reset", () => setTimeout(() => { trigger.textContent = "Select business type"; populate(); }, 0));
  };
  document.addEventListener("DOMContentLoaded", () => setTimeout(enhance, 150));
})();
