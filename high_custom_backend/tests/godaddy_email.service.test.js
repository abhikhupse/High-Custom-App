const test = require("node:test");
const assert = require("node:assert/strict");

const { encryptCredential, decryptCredential } = require("../utils/credentialCipher");
const {
  _private: { smtpConfig, createGoDaddyError },
} = require("../services/godaddy_email.service");

test("GoDaddy mailbox credentials round-trip through authenticated encryption", () => {
  const previous = process.env.GODADDY_CREDENTIAL_KEY;
  process.env.GODADDY_CREDENTIAL_KEY = "test-only-key-with-at-least-32-characters";
  try {
    const encrypted = encryptCredential("mailbox-password");
    assert.notEqual(encrypted.passwordCiphertext, "mailbox-password");
    assert.equal(decryptCredential(encrypted), "mailbox-password");
  } finally {
    if (previous === undefined) delete process.env.GODADDY_CREDENTIAL_KEY;
    else process.env.GODADDY_CREDENTIAL_KEY = previous;
  }
});

test("GoDaddy SMTP defaults use Titan secure submission", () => {
  const config = smtpConfig("sender@example.com", "secret");
  assert.equal(config.host, "smtpout.secureserver.net");
  assert.equal(config.port, 465);
  assert.equal(config.secure, true);
  assert.deepEqual(config.auth, {
    user: "sender@example.com",
    pass: "secret",
  });
});

test("GoDaddy authentication failures are not retried", () => {
  const error = createGoDaddyError({ code: "EAUTH", message: "Invalid login" });
  assert.equal(error.provider, "godaddy");
  assert.equal(error.failureType, "authentication_error");
  assert.equal(error.retryable, false);
});
