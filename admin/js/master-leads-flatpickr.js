(() => {
  "use strict";
  const init = () => {
    if (!window.flatpickr) return;
    document.querySelectorAll(".mlp-custom-range input[type='date']").forEach(input => {
      if (input._flatpickr) return;
      flatpickr(input, { disableMobile:true, dateFormat:"Y-m-d", altInput:true, altFormat:"d M Y", allowInput:false, monthSelectorType:"static" });
    });
  };
  document.addEventListener("DOMContentLoaded", () => setTimeout(init, 300));
})();
