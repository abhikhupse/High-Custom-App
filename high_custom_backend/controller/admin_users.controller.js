const User = require('../model/user.model');
const bcrypt = require('bcrypt');
const { apps } = require('../middleware/user-access');
const fields = 'firstName lastName employerCode email phone profileImage role isActive appRights accessRight createdAt';
const isAdmin = email => String(process.env.ADMIN_EMAILS || '').split(',').some(v => v.trim().toLowerCase() === email.toLowerCase());
function serialize(user) { const u = user.toObject ? user.toObject() : user; return { ...u, isAdministrator: isAdmin(u.email), role: isAdmin(u.email) ? 'Administrator' : (u.role || 'User'), isActive: u.isActive !== false, appRights: u.appRights || apps, accessRight: u.accessRight || 'Full Access' }; }
exports.list = async (req, res, next) => { try { const users = await User.find({ deletedAt: null }).select(fields).sort({ createdAt: -1 }).lean(); res.json({ success: true, currentUserId: String(req.user.id), data: users.map(serialize).sort((a,b) => Number(b.isAdministrator) - Number(a.isAdministrator)) }); } catch(e) { next(e); } };
exports.update = async (req, res, next) => {
  try {
    if (!/^[a-f0-9]{24}$/i.test(req.params.id)) return res.status(400).json({ success:false, message:'Invalid user ID.' });
    const user = await User.findOne({ _id: req.params.id, deletedAt: null });
    if (!user) return res.status(404).json({ success:false, message:'User not found.' });
    if (String(user._id) === String(req.user?.id)) return res.status(403).json({ success:false, message:'Administrators cannot edit their own profile or permissions.' });
    const body = req.body; const changes = {};
    const fail = message => res.status(400).json({success:false,message});
    for (const key of ['firstName','lastName','email','phone','employerCode','role']) if (key in body) {
      if (typeof body[key] !== 'string' || !body[key].trim() || body[key].length > 200) return fail('Please enter a valid ' + key + '.');
      changes[key] = body[key].trim();
    }
    if (changes.email) { changes.email = changes.email.toLowerCase(); if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(changes.email)) return fail('Please enter a valid email.'); }
    if ('isActive' in body) { if (typeof body.isActive !== 'boolean') return fail('Invalid status.'); changes.isActive=body.isActive; }
    if ('appRights' in body) { if (!Array.isArray(body.appRights) || body.appRights.some(v=>!apps.includes(v))) return fail('Invalid application rights.'); changes.appRights=[...new Set(body.appRights)]; }
    if ('accessRight' in body) { if (!['Full Access','View & Edit','View Only','No Access'].includes(body.accessRight)) return fail('Invalid access right.'); changes.accessRight=body.accessRight; }
    if (isAdmin(user.email) && (changes.email && changes.email !== user.email || changes.isActive === false || changes.accessRight && changes.accessRight !== 'Full Access' || changes.appRights && apps.some(v=>!changes.appRights.includes(v)))) return fail('Configured administrator accounts cannot be restricted or have their email changed here.');
    if (changes.email && changes.email !== user.email && isAdmin(changes.email)) return fail('Administrator emails cannot be assigned here.');
    if (body.password) { if (typeof body.password !== 'string' || body.password.length < 8 || Buffer.byteLength(body.password)>72) return fail('Password must be at least 8 characters and at most 72 bytes.'); changes.password=await bcrypt.hash(body.password,12); }
    if (req.file) changes.profileImage='/uploads/profile/' + req.file.filename;
    Object.assign(user, changes); await user.save();
    const safe = await User.findById(user._id).select(fields).lean();
    res.json({success:true,data:serialize(safe)});
  } catch(e) { if(e.code===11000) return res.status(409).json({success:false,message:'Email, phone or employee code is already in use.'}); if(e.name==='ValidationError') return res.status(400).json({success:false,message:'Please check the user details.'}); next(e); }
};
exports.remove = async (req,res,next) => { try {
  if (!/^[a-f0-9]{24}$/i.test(req.params.id)) return res.status(400).json({success:false,message:'Invalid user ID.'});
  const user=await User.findOne({_id:req.params.id,deletedAt:null});
  if(!user) return res.status(404).json({success:false,message:'User not found.'});
  if(String(user._id)===String(req.user.id)||isAdmin(user.email)) return res.status(400).json({success:false,message:'Administrator accounts cannot be removed here.'});
  user.deletedAt=new Date(); user.isActive=false; await user.save(); res.json({success:true});
} catch(e){next(e);} };
const XLSX = require('xlsx');
exports.export = async (req,res,next) => { try {
  const query=String(req.query.q||'').trim().toLowerCase();
  const users=(await User.find({deletedAt:null}).select(fields).lean()).map(serialize).filter(u=>(req.query.inactive!=='true'||!u.isActive)&&[u.employerCode,u.firstName,u.lastName,u.email,u.phone,u.role].join(' ').toLowerCase().includes(query));
  const safe = value => typeof value === 'string' && /^[=+@\-\t\r]/.test(value) ? "'"+value : value;
  const rows=users.map(u=>Object.fromEntries(Object.entries({'Employee Code':u.employerCode,'First Name':u.firstName,'Last Name':u.lastName,Email:u.email,Phone:u.phone,Role:u.role,'App Rights':u.appRights.join(', '),'Access Right':u.accessRight,Status:u.isActive?'Active':'Inactive'}).map(([k,v])=>[k,safe(v)])));
  const book=XLSX.utils.book_new();XLSX.utils.book_append_sheet(book,XLSX.utils.json_to_sheet(rows),'Users');
  res.setHeader('Content-Type','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');res.setHeader('Content-Disposition','attachment; filename="users.xlsx"');res.send(XLSX.write(book,{type:'buffer',bookType:'xlsx'}));
} catch(e){next(e);} };
