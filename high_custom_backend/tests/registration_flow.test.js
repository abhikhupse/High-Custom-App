const test = require("node:test");
const assert = require("node:assert/strict");
const USER = require("../model/user.model");
const bcrypt = require("bcrypt");
let failMail = true;
require.cache[require.resolve("../services/registration_mail.service")] = { exports: {
  createRegistrationTransport: () => ({ close() {}, async sendMail() {
    if (failMail) throw Object.assign(new Error("Blocked SMTP"), { code: "ETIMEDOUT" });
    return { messageId: "test" };
  } }),
} };
const { register } = require("../controller/user.controller");

test("failed OTP registration can retry with original credentials without creating another account", async () => {
  const originals = [USER.findOne, USER.create, bcrypt.hash, bcrypt.compare];
  let stored = null, creates = 0;
  USER.findOne = async () => stored;
  USER.create = async (data) => { creates++; stored = { ...data, _id: "user", createdAt: new Date(), save: async () => {} }; return stored; };
  bcrypt.hash = async () => "hashed";
  bcrypt.compare = async (password) => password === "original-password";
  const req = { body: { firstName: "Test", lastName: "User", phone: "1234567890", email: "test@example.com", employerCode: "ABC", password: "original-password" } };
  const res = { status(code) { this.code = code; return this; }, json(body) { this.body = body; return this; } };
  try {
    await register(req, res);
    assert.equal(res.code, 503);
    assert.equal(res.body.code, "ETIMEDOUT");
    assert.equal(stored.isEmailVerified, false);
    failMail = false;
    await register(req, res);
    assert.equal(res.code, 201);
    assert.equal(creates, 1);
    await register({ body: { ...req.body, password: "wrong-password" } }, res);
    assert.equal(res.code, 400);
    assert.equal(stored.password, "hashed");
  } finally {
    [USER.findOne, USER.create, bcrypt.hash, bcrypt.compare] = originals;
  }
});
