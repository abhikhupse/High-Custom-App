document.addEventListener('DOMContentLoaded', () => {
  'use strict';
  const $ = id => document.getElementById(id);
  const api = localStorage.getItem('highCustomApiBase') || (['localhost','127.0.0.1'].includes(location.hostname) ? 'http://localhost:3000/api' : 'https://high-custom-app.onrender.com/api');
  const token = localStorage.getItem('highCustomAdminToken');
  if (!token) { location.replace('/admin-login.html'); return; }
  let currentUserId = null;
  let users = [], inactive = false, selected = null, kind = null;
  const esc = v => String(v ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const message = text => { $('userApiMessage').textContent = text; $('userApiMessage').classList.toggle('d-none', !text); };
  async function request(path, options = {}) {
    const response = await fetch(api + path, {...options, headers:{Accept:'application/json',Authorization:'Bearer '+token,...(options.body && !(options.body instanceof FormData) ? {'Content-Type':'application/json'}:{}),...options.headers}});
    const data = await response.json().catch(()=>({}));
    if (response.status === 401) { localStorage.removeItem('highCustomAdminToken'); location.replace('/admin-login.html?reason=access'); }
    if (!response.ok || data.success === false) throw new Error(data.message || 'Unable to load users. Check the backend connection.');
    return data;
  }
  const isSelf = user => String(user._id) === currentUserId;
  const roleClass = user => user.isAdministrator ? 'role-administrator' : ({'Sales Manager':'role-sales','Marketing':'role-marketing','Support':'role-support','Viewer':'role-viewer'}[user.role] || 'role-user');
  const filtered = () => { const query=$('globalSearch').value.trim().toLowerCase(); return users.filter(u=>(!inactive || !u.isActive) && [u.employerCode,u.firstName,u.lastName,u.phone,u.email,u.role].join(' ').toLowerCase().includes(query)); };
  function render() {
    const rows=filtered().sort((a,b)=>Number(b.isAdministrator)-Number(a.isAdministrator)); $('totalUsersCount').textContent=`Total Users: ${rows.length}`;
    $('usersTable').querySelector('tbody').innerHTML=rows.length ? rows.map(u=>`<tr data-id="${esc(u._id)}" class="${u.isAdministrator ? 'administrator-row' : ''}"><td><button class="btn btn-sm btn-outline-primary" data-action="edit" ${isSelf(u) ? 'disabled title="You cannot edit your own profile"' : ''} aria-label="Edit ${esc(u.firstName)}"><i class="fas fa-pen"></i></button></td><td>${esc(u.employerCode)}</td><td>${esc(u.firstName)} ${esc(u.lastName)}${isSelf(u) ? ' <small class="text-muted">(You)</small>' : ''}</td><td>${esc(u.phone)}</td><td>${esc(u.email)}</td><td><span class="badge ${roleClass(u)}">${u.isAdministrator ? '<i class="fas fa-crown me-1" aria-hidden="true"></i>' : ''}${esc(u.role)}</span></td><td><button class="rights-edit-btn" data-action="app" ${isSelf(u) ? 'disabled' : ''} title="${esc(u.appRights.join(', ') || 'None')}" aria-label="Edit application rights"><i class="fas fa-pen"></i></button></td><td><button class="rights-edit-btn" data-action="access" ${isSelf(u) ? 'disabled' : ''} title="${esc(u.accessRight)}" aria-label="Edit access rights"><i class="fas fa-pen"></i></button></td><td><div class="form-check form-switch m-0"><input type="checkbox" class="form-check-input" data-action="status" ${isSelf(u) ? 'disabled' : ''} aria-label="Active status for ${esc(u.firstName)}" ${u.isActive?'checked':''}></div></td><td><button class="btn btn-sm btn-outline-danger" data-action="delete" ${isSelf(u) || u.isAdministrator ? 'disabled title="Administrator accounts cannot be removed"' : ''} aria-label="Remove ${esc(u.firstName)}"><i class="fas fa-trash"></i></button></td></tr>`).join('') : '<tr><td colspan="10" class="text-center py-4">No users found.</td></tr>';
  }
  async function update(id, data) { const result=await request('/admin/users/'+id,{method:'PATCH',body:data instanceof FormData?data:JSON.stringify(data)}); users=users.map(u=>u._id===id?result.data:u); render(); message(''); }
  $('globalSearch').addEventListener('input',render);
  $('filterInactiveBtn').onclick=()=>{inactive=true;render();};
  $('showAllBtn').onclick=()=>{inactive=false;render();};
  $('usersTable').addEventListener('click',async event=>{
    const button=event.target.closest('[data-action]'); if(!button || button.disabled) return;
    const user=users.find(u=>u._id===button.closest('tr').dataset.id); if(!user || isSelf(user))return;
    selected=user; kind=button.dataset.action; message('');
    if(kind==='app'||kind==='access') {
      $('rightsUserName').textContent=user.firstName+' '+user.lastName;
      $('rightsModalTitle').textContent=kind==='app'?'Select App Rights':'Select Access Right';
      $('appRightsEditor').classList.toggle('d-none',kind!=='app'); $('accessRightsEditor').classList.toggle('d-none',kind!=='access');
      document.querySelectorAll('.app-right-check').forEach(c=>c.checked=user.appRights.includes(c.value)); $('modalAccessRight').value=user.accessRight;
      bootstrap.Modal.getOrCreateInstance($('rightsModal')).show();
    } else if(kind==='edit') {
      $('userForm').reset(); $('userId').value=user._id;
      for(const [id,key] of Object.entries({name:'firstName',lastname:'lastName',mobile:'phone',email:'email',user_code:'employerCode'})) $(id).value=user[key]||'';
      $('imagePreview').src=user.profileImage ? new URL(user.profileImage, api.replace(/\/api\/?$/,'')+'/').href : '/images/company-logo.png';
      bootstrap.Modal.getOrCreateInstance($('addEditUserModal')).show();
    } else if(kind==='status') {
      button.disabled=true; try {await update(user._id,{isActive:button.checked});} catch(e){button.checked=user.isActive;message(e.message);} finally{button.disabled=false;}
    } else if(kind==='delete') {
      if(!confirm(`Remove ${user.firstName} ${user.lastName}? They will no longer be able to sign in. Their related records will be preserved.`))return;
      button.disabled=true; try {await request('/admin/users/'+user._id,{method:'DELETE'});users=users.filter(u=>u._id!==user._id);render();}catch(e){message(e.message);}finally{button.disabled=false;}
    }
  });
  $('saveRightsBtn').onclick=async()=>{
    if(!selected)return; const button=$('saveRightsBtn');button.disabled=true;
    try{await update(selected._id,kind==='app'?{appRights:[...document.querySelectorAll('.app-right-check:checked')].map(c=>c.value)}:{accessRight:$('modalAccessRight').value});bootstrap.Modal.getOrCreateInstance($('rightsModal')).hide();}
    catch(e){alert(e.message);}finally{button.disabled=false;}
  };
  $('userForm').addEventListener('submit',async event=>{
    event.preventDefault(); const button=event.target.querySelector('[type="submit"]');button.disabled=true;
    const data=new FormData(); for(const [id,key] of Object.entries({name:'firstName',lastname:'lastName',mobile:'phone',email:'email',user_code:'employerCode',password:'password'}))data.append(key,$(id).value);
    if($('profileImage').files[0])data.append('profileImage',$('profileImage').files[0]);
    try{await update($('userId').value,data);bootstrap.Modal.getOrCreateInstance($('addEditUserModal')).hide();}catch(e){alert(e.message);}finally{button.disabled=false;}
  });
  $('exportExcelBtn').onclick=async()=>{
    const button=$('exportExcelBtn');button.disabled=true;
    try {const response=await fetch(api+'/admin/users-export?'+new URLSearchParams({q:$('globalSearch').value,inactive:String(inactive)}),{headers:{Authorization:'Bearer '+token}});if(!response.ok)throw new Error('Unable to export users.');const url=URL.createObjectURL(await response.blob());const a=document.createElement('a');a.href=url;a.download='users.xlsx';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);}catch(e){message(e.message);}finally{button.disabled=false;}
  };
  $('printCardBtn').onclick=()=>{
    const popup=window.open('','_blank');if(!popup){message('Allow pop-ups to print user cards.');return;}
    popup.document.write('<!doctype html><title>User Cards</title><style>body{font:16px Arial;display:flex;flex-wrap:wrap;gap:20px}article{border:1px solid #aaa;padding:24px;width:280px;break-inside:avoid}p{overflow-wrap:anywhere}</style>'+filtered().map(u=>`<article><h2>${esc(u.firstName)} ${esc(u.lastName)}</h2><p>${esc(u.employerCode)} Â· ${esc(u.role)}</p><p>${esc(u.email)}</p><p>${esc(u.phone)}</p></article>`).join(''));popup.document.close();popup.print();
  };
  request('/admin/users').then(data=>{currentUserId=String(data.currentUserId);users=data.data;render();}).catch(e=>{$('usersTable').querySelector('tbody').innerHTML='<tr><td colspan="10" class="text-center py-4">Users could not be loaded. Refresh to retry.</td></tr>';$('totalUsersCount').textContent='Total Users: â€”';message(e.message);});
});
