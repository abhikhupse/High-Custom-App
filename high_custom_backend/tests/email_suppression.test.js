const test = require("node:test");
const assert = require("node:assert/strict");
const DELIVERY = require("../model/sequence_delivery.model");
const SUPPRESSION = require("../model/email_suppression.model");
// The suppression test must never load or invoke an external mail transport.
const transportPath = require.resolve("../services/email.service");
require.cache[transportPath] = { exports: { sendSequenceEmail: async () => {
  throw new Error("Suppressed leads must never reach a mail transport");
} } };
const { sendSequenceToLead } = require("../services/sequence.service");

test("suppressed addresses and replied leads stop before provider or delivery creation", async () => {
  const originals = [SUPPRESSION.findOne, DELIVERY.exists];
  const sequence = { _id: "sequence", userId: "user" };
  const lead = { _id: "reimported-lead", email: "LEAD@example.com", tracking: true };
  try {
    SUPPRESSION.findOne = (filter) => {
      assert.equal(filter.email, "lead@example.com");
      return { select: () => ({ lean: async () => ({ reason: "unsubscribe" }) }) };
    };
    DELIVERY.exists = async () => { throw new Error("Should short-circuit"); };
    assert.equal((await sendSequenceToLead({ sequence, lead })).reason, "lead_unsubscribe");
    SUPPRESSION.findOne = () => ({ select: () => ({ lean: async () => null }) });
    DELIVERY.exists = async (filter) => {
      assert.deepEqual(filter.repliedAt, { $ne: null });
      return true;
    };
    assert.equal((await sendSequenceToLead({ sequence, lead })).reason, "lead_already_replied");
  } finally {
    [SUPPRESSION.findOne, DELIVERY.exists] = originals;
  }
});
