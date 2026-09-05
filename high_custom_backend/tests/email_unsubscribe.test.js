const test = require("node:test");
const assert = require("node:assert/strict");
const DELIVERY = require("../model/sequence_delivery.model");
const SEQUENCE = require("../model/sequence.model");
const LEAD = require("../model/leads.model");
const SUPPRESSION = require("../model/email_suppression.model");
const { confirmResponse } = require("../controller/email_tracking.controller");

test("one-click unsubscribe persists suppression and is idempotent without a browser session", async () => {
  const originals = [DELIVERY.findOne, SEQUENCE.updateOne, LEAD.updateOne, SUPPRESSION.updateOne];
  let changes = 0, suppressions = 0, disabled = 0;
  const delivery = { userId: "user", leadId: "lead", sequenceId: "sequence", email: "lead@example.com", save: async () => {} };
  DELIVERY.findOne = async () => delivery;
  SEQUENCE.updateOne = async () => { changes++; };
  SUPPRESSION.updateOne = async (filter, update, options) => {
    assert.deepEqual(filter, { userId: "user", email: "lead@example.com" });
    assert.equal(update.$setOnInsert.reason, "unsubscribe");
    assert.equal(options.upsert, true);
    suppressions++;
  };
  LEAD.updateOne = async (filter, update) => { assert.equal(update.$set.tracking, false); disabled++; };
  const statuses = [];
  try {
    const req = { params: { trackingId: "opaque", response: "notInterested" }, body: { "List-Unsubscribe": "One-Click" } };
    const res = { sendStatus: (code) => statuses.push(code) };
    await confirmResponse(req, res);
    await confirmResponse(req, res);
    assert.deepEqual(statuses, [200, 200]);
    assert.equal(changes, 1);
    assert.equal(suppressions, 2);
    assert.equal(disabled, 2);
  } finally {
    [DELIVERY.findOne, SEQUENCE.updateOne, LEAD.updateOne, SUPPRESSION.updateOne] = originals;
  }
});
