const { ImapFlow } = require("imapflow");

const GODADDY_INTEGRATION = require("../model/godaddy_integration.model");
const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");
const { decryptCredential } = require("../utils/credentialCipher");

const LOCK_MS = 2 * 60 * 1000;

function normalizeEmail(value) {
  const text = String(value || "").trim().toLowerCase();
  const match = text.match(/[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9.-]+/i);
  return match ? match[0].toLowerCase() : "";
}

function addressEmail(addresses) {
  const first = Array.isArray(addresses) ? addresses[0] : null;
  return normalizeEmail(first?.address || first?.mailbox || "");
}

function createClient(integration) {
  return new ImapFlow({
    host: process.env.GODADDY_IMAP_HOST || "imap.secureserver.net",
    port: Number(process.env.GODADDY_IMAP_PORT || 993),
    secure: String(process.env.GODADDY_IMAP_SECURE || "true") !== "false",
    auth: {
      user: integration.email,
      pass: decryptCredential(integration),
    },
    logger: false,
  });
}

async function syncGoDaddyReplies(integration) {
  const locked = await GODADDY_INTEGRATION.findOneAndUpdate(
    {
      _id: integration._id,
      $or: [
        { replySyncLockUntil: null },
        { replySyncLockUntil: { $exists: false } },
        { replySyncLockUntil: { $lt: new Date() } },
      ],
    },
    { $set: { replySyncLockUntil: new Date(Date.now() + LOCK_MS) } },
    { returnDocument: "after" },
  ).select("+passwordCiphertext +passwordIv +passwordAuthTag");

  if (!locked) return { skipped: true, replied: 0 };

  const syncStartedAt = new Date();
  // Re-scan a small overlap so a temporary matching/database issue cannot
  // permanently skip a reply after the sync cursor advances.
  const cursor = locked.lastReplySyncAt || locked.connectedAt || new Date();
  const since = new Date(
    Math.max(
      new Date(cursor).getTime() - 24 * 60 * 60 * 1000,
      Date.now() - 7 * 24 * 60 * 60 * 1000,
    ),
  );
  const client = createClient(locked);
  let replied = 0;
  let checked = 0;

  try {
    await client.connect();
    const mailboxLock = await client.getMailboxLock("INBOX");
    try {
      for await (const message of client.fetch(
        { since },
        { uid: true, envelope: true },
      )) {
        checked += 1;
        const from = addressEmail(message.envelope?.from);
        const receivedAt = message.envelope?.date || syncStartedAt;
        const rawMessageId = String(message.envelope?.messageId || message.uid);
        const replyMessageId = `godaddy:${rawMessageId}`;
        const inReplyTo = String(message.envelope?.inReplyTo || "").trim();

        if (!from) continue;
        if (await SEQUENCE_DELIVERY.exists({ userId: locked.userId, replyMessageId })) continue;

        // Prefer the RFC In-Reply-To header. This correctly handles replies
        // sent from the same mailbox and is more precise than sender matching.
        let delivery = inReplyTo
          ? await SEQUENCE_DELIVERY.findOne({
              userId: locked.userId,
              messageId: `godaddy:${inReplyTo}`,
              status: "sent",
              repliedAt: null,
            })
          : null;

        // Some clients omit In-Reply-To. Fall back to matching the lead's
        // sender address, but never treat an unthreaded self-message as reply.
        if (!delivery && from !== normalizeEmail(locked.email)) {
          delivery = await SEQUENCE_DELIVERY.findOne({
            userId: locked.userId,
            email: from,
            status: "sent",
            repliedAt: null,
            sentAt: { $lte: receivedAt },
          }).sort({ sentAt: -1 });
        }

        if (!delivery) continue;
        const result = await SEQUENCE_DELIVERY.updateOne(
          { _id: delivery._id, repliedAt: null },
          {
            $set: {
              repliedAt: receivedAt,
              replyMessageId,
              replyFrom: from,
              replySubject: String(message.envelope?.subject || "").slice(0, 500),
              replySnippet: "Reply received in GoDaddy mailbox",
            },
          },
        );
        if (result.modifiedCount === 1) replied += 1;
      }
    } finally {
      mailboxLock.release();
    }

    await GODADDY_INTEGRATION.updateOne(
      { _id: locked._id },
      {
        $set: {
          lastReplySyncAt: syncStartedAt,
          replySyncLockUntil: null,
          replySyncLastError: null,
        },
      },
    );
    return { checked, replied };
  } catch (error) {
    await GODADDY_INTEGRATION.updateOne(
      { _id: locked._id },
      {
        $set: {
          replySyncLockUntil: null,
          replySyncLastError: String(error.message || error).slice(0, 1000),
        },
      },
    );
    throw error;
  } finally {
    await client.logout().catch(() => {});
  }
}

async function syncAllGoDaddyReplies() {
  const integrations = await GODADDY_INTEGRATION.find({}).select(
    "+passwordCiphertext +passwordIv +passwordAuthTag",
  );
  let processed = 0;
  let replies = 0;
  for (const integration of integrations) {
    try {
      const result = await syncGoDaddyReplies(integration);
      if (!result.skipped) processed += 1;
      replies += result.replied || 0;
    } catch (error) {
      console.error(`GoDaddy reply sync failed for ${integration.email}:`, error.message);
    }
  }
  return { found: integrations.length, processed, replies };
}

module.exports = { syncGoDaddyReplies, syncAllGoDaddyReplies };
