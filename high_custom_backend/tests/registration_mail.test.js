const test = require("node:test");
const assert = require("node:assert/strict");
const axios = require("axios");
const GMAIL = require("../model/gmail_integration.model");
const { createRegistrationTransport } = require("../services/registration_mail.service");

test("Render OTP uses HTTPS with only the configured sender and never SMTP", async () => {
  const saved = { ...process.env };
  const originalFind = GMAIL.findOne, originalPost = axios.post;
  process.env.RENDER = "true";
  delete process.env.OTP_EMAIL_TRANSPORT;
  process.env.EMAIL_USER = "owner@example.com";
  process.env.GOOGLE_CLIENT_ID = "test-client";
  process.env.GOOGLE_CLIENT_SECRET = "test-secret";
  let requests = 0;
  GMAIL.findOne = (filter) => {
    assert.deepEqual(filter, { email: "owner@example.com" });
    return { sort: () => ({ lean: async () => ({ refreshToken: "fake-refresh" }) }) };
  };
  axios.post = async (url, data) => {
    requests++;
    if (url === "https://oauth2.googleapis.com/token") return { data: { access_token: "fake-access" } };
    assert.equal(url, "https://gmail.googleapis.com/gmail/v1/users/me/messages/send");
    const mime = Buffer.from(data.raw, "base64url").toString();
    assert.match(mime, /From: owner@example.com/);
    assert.match(mime, /To: recipient@example.com/);
    return { data: { id: "accepted" } };
  };
  try {
    const transport = createRegistrationTransport();
    assert.deepEqual(await transport.sendMail({ to: "recipient@example.com", subject: "OTP", text: "123456" }), { messageId: "accepted" });
    transport.close();
    assert.equal(requests, 2);
    GMAIL.findOne = () => ({ sort: () => ({ lean: async () => null }) });
    const missing = createRegistrationTransport();
    await assert.rejects(missing.sendMail({}), { code: "OTP_GMAIL_RECONNECT" });
    missing.close();
    assert.equal(requests, 2);
  } finally {
    GMAIL.findOne = originalFind; axios.post = originalPost;
    process.env = saved;
  }
});

test("production and Render URL environments select HTTPS even without RENDER=true", () => {
  const saved = { ...process.env };
  try {
    delete process.env.RENDER;
    delete process.env.OTP_EMAIL_TRANSPORT;
    process.env.RENDER_EXTERNAL_URL = "https://example.onrender.com";
    assert.equal(typeof createRegistrationTransport().sendMail, "function");
    delete process.env.RENDER_EXTERNAL_URL;
    process.env.NODE_ENV = "production";
    assert.equal(typeof createRegistrationTransport().sendMail, "function");
  } finally {
    process.env = saved;
  }
});
