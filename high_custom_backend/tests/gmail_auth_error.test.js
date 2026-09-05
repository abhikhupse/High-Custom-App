const test = require("node:test");
const assert = require("node:assert/strict");
const { isInvalidGrant } = require("../services/gmail_reply.service");

test("invalid_grant is recognized in Google error shapes", () => {
  assert.equal(isInvalidGrant(new Error("invalid_grant")), true);
  assert.equal(isInvalidGrant({ response: { data: { error: "invalid_grant" } } }), true);
  assert.equal(isInvalidGrant({ cause: { message: "invalid_grant" } }), true);
  assert.equal(isInvalidGrant({ response: { status: 429 }, message: "rate limited" }), false);
});
