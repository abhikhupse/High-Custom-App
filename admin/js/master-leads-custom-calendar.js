(() => {
  "use strict";
  const init = () => {
    const range = document.querySelector(".mlp-custom-range");
    if (!range || range.dataset.calendarReady) return;
    range.dataset.calendarReady = "true";
    const inputs = [...range.querySelectorAll("input[type='date']")];
    if (inputs.length !== 2) return;
    inputs.forEach(input => { input.hidden = true; });
    const buttons = ["Start date", "End date"].map((label, index) => { const button=document.createElement("button"); button.type="button"; button.className="mlp-calendar-field"; button.textContent=label; inputs[index].after(button); return button; });
    const popover = document.createElement("div"); popover.className="mlp-calendar-popover"; range.append(popover);
    let target = 0, cursor = new Date();
    const pad = value => String(value).padStart(2,"0");
    const iso = date => `${date.getFullYear()}-${pad(date.getMonth()+1)}-${pad(date.getDate())}`;
    const display = date => new Intl.DateTimeFormat("en-GB",{day:"2-digit",month:"short",year:"numeric"}).format(date);
    const paint = () => {
      const year=cursor.getFullYear(), month=cursor.getMonth(), first=new Date(year,month,1), last=new Date(year,month+1,0), start=first.getDay(), selected=inputs[target].value;
      const days=[]; for(let i=0;i<start;i++) days.push('<span></span>'); for(let day=1;day<=last.getDate();day++){const value=iso(new Date(year,month,day));days.push(`<button type="button" class="mlp-calendar-day ${value===selected?"selected":""}" data-date="${value}">${day}</button>`);}
      popover.innerHTML=`<div class="mlp-calendar-head"><button type="button" data-prev><i class="fa-solid fa-chevron-left"></i></button><span>${new Intl.DateTimeFormat("en-GB",{month:"long",year:"numeric"}).format(cursor)}</span><button type="button" data-next><i class="fa-solid fa-chevron-right"></i></button></div><div class="mlp-calendar-week"><span>Su</span><span>Mo</span><span>Tu</span><span>We</span><span>Th</span><span>Fr</span><span>Sa</span></div><div class="mlp-calendar-days">${days.join("")}</div><div class="mlp-calendar-footer"><button type="button" data-clear>Clear</button><button type="button" data-today>Today</button></div>`;
    };
    const open = index => { target=index; cursor=inputs[index].value?new Date(`${inputs[index].value}T12:00:00`):new Date(); paint(); popover.classList.add("show"); };
    buttons.forEach((button,index)=>button.addEventListener("click",event=>{event.stopPropagation();open(index);}));
    popover.addEventListener("click",event=>{event.stopPropagation();if(event.target.closest("[data-prev]")){cursor.setMonth(cursor.getMonth()-1);paint();return;}if(event.target.closest("[data-next]")){cursor.setMonth(cursor.getMonth()+1);paint();return;}if(event.target.closest("[data-clear]")){inputs[target].value="";buttons[target].textContent=target?"End date":"Start date";popover.classList.remove("show");return;}if(event.target.closest("[data-today]")){const now=new Date();inputs[target].value=iso(now);buttons[target].textContent=display(now);popover.classList.remove("show");return;}const day=event.target.closest("[data-date]");if(day){const chosen=new Date(`${day.dataset.date}T12:00:00`);inputs[target].value=day.dataset.date;buttons[target].textContent=display(chosen);popover.classList.remove("show");}});
    document.addEventListener("click",event=>{if(!range.contains(event.target))popover.classList.remove("show");});
  };
  document.addEventListener("DOMContentLoaded",()=>setTimeout(init,270));
})();
