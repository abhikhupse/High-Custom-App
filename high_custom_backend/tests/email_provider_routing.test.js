const test = require("node:test");
const assert = require("node:assert/strict");

const { _private } = require("../services/email.service");

test("recognizes Gmail and Zoho personal recipient domains", () => {
  assert.equal(_private.providerFromDomain("gmail.com"), "gmail");
  assert.equal(_private.providerFromDomain("googlemail.com"), "gmail");
  assert.equal(_private.providerFromDomain("zohomail.in"), "zoho");
  assert.equal(_private.providerFromDomain("example.com"), null);
});

test("recognizes hosted recipient domains from MX records", () => {
  assert.equal(
    _private.providerFromMxRecords([{ exchange: "aspmx.l.google.com" }]),
    "gmail",
  );
  assert.equal(
    _private.providerFromMxRecords([{ exchange: "mx.zoho.in" }]),
    "zoho",
  );
  assert.equal(
    _private.providerFromMxRecords([{ exchange: "mx1.titan.email" }]),
    "godaddy",
  );
  assert.equal(
    _private.providerFromMxRecords([{ exchange: "mail.example.test" }]),
    null,
  );
});
