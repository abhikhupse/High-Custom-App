(() => {
  "use strict";
  if (new URLSearchParams(location.search).get("status") === "interested") return;
  const enhance = () => {
    const root = document.querySelector(".mlp"), select = root?.querySelector(".mlp-page-size");
    if (!root || !select || select.dataset.polished) return;
    [50, 100].forEach(value => { if (![...select.options].some(option => Number(option.value) === value)) select.insertAdjacentHTML("beforeend", `<option value="${value}">${value} / page</option>`); });
    select.dataset.polished = "true";
    const picker = document.createElement("div");
    picker.className = "mlp-page-picker";
    picker.innerHTML = '<button type="button" class="mlp-page-trigger">10 / page</button><div class="mlp-page-menu"></div>';
    select.after(picker); select.hidden = true;
    const trigger = picker.querySelector(".mlp-page-trigger"), menu = picker.querySelector(".mlp-page-menu");
    const paint = () => { menu.innerHTML = [...select.options].map(option => `<button type="button" class="mlp-page-option ${select.value === option.value ? "selected" : ""}" data-value="${option.value}">${option.textContent}</button>`).join(""); trigger.textContent = select.options[select.selectedIndex]?.textContent || "10 / page"; };
    paint();
    trigger.addEventListener("click", () => picker.classList.toggle("open"));
    menu.addEventListener("click", event => { const option=event.target.closest("[data-value]"); if(!option)return; select.value=option.dataset.value; select.dispatchEvent(new Event("change",{bubbles:true})); paint(); picker.classList.remove("open"); });
    document.addEventListener("click", event => { if (!picker.contains(event.target)) picker.classList.remove("open"); });
  };
  document.addEventListener("DOMContentLoaded", () => setTimeout(() => { enhance(); const root=document.querySelector(".mlp"); if(root) new MutationObserver(enhance).observe(root,{childList:true,subtree:true}); }, 280));
})();
