const test=require('node:test');const assert=require('node:assert/strict');
const {denied,apps}=require('../middleware/user-access');
test('existing accounts retain access and restricted accounts are rejected',()=>{
 assert.equal(denied({},'/api/leads','GET'),null);
 for(const u of [null,{isActive:false},{deletedAt:new Date()},{accessRight:'No Access'}])assert.ok(denied(u,'/api/leads','GET'));
 assert.ok(denied({appRights:[]},'/api/leads','GET'));
 assert.equal(denied({appRights:['Leads']},'/api/leads','GET'),null);
 assert.ok(denied({accessRight:'View Only'},'/api/leads','POST'));
 assert.equal(denied({accessRight:'View Only'},'/api/user/logout','POST'),null);
 assert.ok(denied({appRights:['Dashboard']},'/api/admin/users','GET'));
});
const User=require('../model/user.model');const ctrl=require('../controller/admin_users.controller');
function response(){return {code:200,status(c){this.code=c;return this;},json(d){this.data=d;return this;}};}
test('admin updates validate input, block privilege assignment and save rights',async()=>{
 const original=User.findOne, byId=User.findById, emails=process.env.ADMIN_EMAILS;process.env.ADMIN_EMAILS='admin@example.test';
 let saved=0;const user={_id:'a'.repeat(24),email:'member@example.test',save:async()=>saved++};
 User.findOne=async()=>user;User.findById=()=>({select:()=>({lean:async()=>({...user})})});
 try {
  for(const body of [{appRights:['Invalid']},{isActive:'false'},{accessRight:'invalid'},{email:'admin@example.test'},{password:'short'}]){const res=response();await ctrl.update({params:{id:user._id},body},res,e=>{throw e});assert.equal(res.code,400);}
  assert.equal(saved,0);
  let res=response();await ctrl.update({params:{id:user._id},body:{appRights:['Leads'],accessRight:'View Only'}},res,e=>{throw e});assert.equal(res.code,200);assert.equal(saved,1);assert.deepEqual(user.appRights,['Leads']);
  user.email='admin@example.test';res=response();await ctrl.update({params:{id:user._id},body:{isActive:false}},res,e=>{throw e});assert.equal(res.code,400);assert.equal(saved,1);
  res=response();await ctrl.remove({params:{id:user._id},user:{id:'b'.repeat(24)}},res,e=>{throw e});assert.equal(res.code,400);
 }finally{User.findOne=original;User.findById=byId;if(emails===undefined)delete process.env.ADMIN_EMAILS;else process.env.ADMIN_EMAILS=emails;}
});
test('administrator cannot edit self through either profile endpoint', async()=>{
 const original=User.findOne, emails=process.env.ADMIN_EMAILS;process.env.ADMIN_EMAILS='admin@example.test';
 const id='a'.repeat(24);let saved=false;User.findOne=async()=>({_id:id,email:'admin@example.test',save:async()=>saved=true});
 try {
 const res=response();await ctrl.update({params:{id},user:{id},body:{firstName:'Changed'}},res,e=>{throw e});assert.equal(res.code,403);assert.equal(saved,false);
 assert.ok(denied({email:'admin@example.test'},'/api/user/edit-profile','PUT'));
 assert.equal(denied({email:'member@example.test'},'/api/user/edit-profile','PUT'),null);
 } finally {User.findOne=original;if(emails===undefined)delete process.env.ADMIN_EMAILS;else process.env.ADMIN_EMAILS=emails;}
});
test('list identifies current user and places configured administrator first',async()=>{
 const original=User.find, emails=process.env.ADMIN_EMAILS;process.env.ADMIN_EMAILS='admin@example.test';
 User.find=()=>({select:()=>({sort:()=>({lean:async()=>[{_id:'member',email:'member@example.test'},{_id:'admin',email:'admin@example.test'}]})})});
 try {const res=response();await ctrl.list({user:{id:'admin'}},res,e=>{throw e});assert.equal(res.data.currentUserId,'admin');assert.equal(res.data.data[0]._id,'admin');assert.equal(res.data.data[0].isAdministrator,true);}finally{User.find=original;if(emails===undefined)delete process.env.ADMIN_EMAILS;else process.env.ADMIN_EMAILS=emails;}
});
