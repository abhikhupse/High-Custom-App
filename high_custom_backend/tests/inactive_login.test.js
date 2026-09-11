const test = require('node:test');
const assert = require('node:assert/strict');
const User = require('../model/user.model');
const controller = require('../controller/user.controller');
const { denied } = require('../middleware/user-access');
test('inactive users cannot log in by email or employee code and receive the requested message', async () => {
 const original = User.findOne;
 User.findOne = async () => ({ isActive: false });
 try {
  for (const identity of [{email:'inactive@example.test'}, {employerCode:'INACTIVE001'}]) {
   const res = {status(code){this.code=code;return this;},json(body){this.body=body;return this;}};
   await controller.login({body:{...identity,password:'test-password'}},res);
   assert.equal(res.code,403);
   assert.equal(res.body.success,false);
   assert.equal(res.body.message,'Your account is inactive. Please contact admin.');
   assert.equal(res.body.token,undefined);
  }
  assert.equal(denied({isActive:false},'/api/user/profile','GET'),'Your account is inactive. Please contact admin.');
 } finally { User.findOne=original; }
});
