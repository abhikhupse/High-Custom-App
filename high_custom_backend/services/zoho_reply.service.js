const axios = require("axios");

const ZOHO_INTEGRATION = require("../model/zoho_integration.model");
const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");

const LOCK_MS = 2 * 60 * 1000;

function accountsBaseUrl() {
  return String(process.env.ZOHO_ACCOUNTS_BASE_URL || "https://accounts.zoho.in").replace(/\/$/, "");
}

function mailBaseUrl() {
  return String(process.env.ZOHO_MAIL_BASE_URL || "https://mail.zoho.in").replace(/\/$/, "");
}

function normalizeEmail(value) {
  const text = String(value || "").trim().toLowerCase();
  const angle = text.match(/<([^<>\s]+@[^<>\s]+)>/);
  if (angle) return angle[1];
  const match = text.match(/[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9.-]+/i);
  return match ? match[0].toLowerCase() : "";
}

function zohoItems(payload) {
  if (Array.isArray(payload?.data)) return payload.data;
  if (Array.isArray(payload)) return payload;
  return [];
}

async function refreshAccessToken(integration) {
  if (integration.expiresAt && integration.expiresAt.getTime() > Date.now() + 60_000) {
    return integration.accessToken;
  }

  const body = new URLSearchParams({
    refresh_token: integration.refreshToken,
    client_id: process.env.ZOHO_CLIENT_ID,
    client_secret: process.env.ZOHO_CLIENT_SECRET,
    grant_type: "refresh_token",
  });
  const response = await axios.post(`${accountsBaseUrl()}/oauth/v2/token`, body, {
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
  });

  if (!response.data?.access_token) {
    throw new Error(response.data?.error || "Zoho access-token refresh failed.");
  }

  integration.accessToken = response.data.access_token;
  integration.expiresAt = new Date(Date.now() + Number(response.data.expires_in || 3600) * 1000);
  await integration.save();
  return integration.accessToken;
}

async function zohoGet(integration, path, params = {}) {
  const accessToken = await refreshAccessToken(integration);
  const url = `${mailBaseUrl()}${path}`;
  try {
    const response = await axios.get(url, {
      params,
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: `Zoho-oauthtoken ${accessToken}`,
      },
    });
    return response.data;
  } catch (error) {
    const detail =
      error.response?.data?.data?.moreInfo ||
      error.response?.data?.status?.description ||
      error.response?.data?.error ||
      error.message;
    const wrapped = new Error(`Zoho Mail API request failed (${path}): ${detail}`);
    wrapped.statusCode = error.response?.status;
    wrapped.zohoResponse = error.response?.data;
    wrapped.zohoPath = path;
    throw wrapped;
  }
}

async function syncZohoReplies(integration) {
  const locked = await ZOHO_INTEGRATION.findOneAndUpdate(
    {
      _id: integration._id,
      $or: [
        { syncLockUntil: null },
        { syncLockUntil: { $exists: false } },
        { syncLockUntil: { $lt: new Date() } },
      ],
    },
    { $set: { syncLockUntil: new Date(Date.now() + LOCK_MS) } },
    { returnDocument: "after" },
  );

  if (!locked) return { skipped: true, reason: "locked" };

  const syncStartedAt = new Date();
  const since = locked.lastSyncAt || locked.connectedAt || syncStartedAt;

  try {
    const foldersPayload = await zohoGet(locked, `/api/accounts/${locked.accountId}/folders`);
    const inbox = zohoItems(foldersPayload).find(
      (folder) => String(folder.folderType || folder.folderName || "").toLowerCase() === "inbox",
    );
    if (!inbox?.folderId) throw new Error("Zoho Inbox folder was not found.");

    const messagesPayload = await zohoGet(
      locked,
      `/api/accounts/${locked.accountId}/messages/view`,
      { folderId: inbox.folderId, start: 1, limit: 200 },
    );
    const messages = zohoItems(messagesPayload);
    let replied = 0;

    for (const message of messages) {
      const messageId = String(message.messageId || message.messageID || "");
      const from = normalizeEmail(message.sender || message.fromAddress || message.from);
      const receivedAt = new Date(Number(message.receivedTime || message.receivedDate || message.sentDateInGMT || 0));
      if (!messageId || !from || Number.isNaN(receivedAt.getTime()) || receivedAt <= since) continue;
      if (from === normalizeEmail(locked.email)) continue;

      const duplicate = await SEQUENCE_DELIVERY.exists({
        userId: locked.userId,
        replyMessageId: `zoho:${messageId}`,
      });
      if (duplicate) continue;

      const candidates = await SEQUENCE_DELIVERY.find({
        userId: locked.userId,
        status: "sent",
        repliedAt: null,
        sentAt: { $lte: receivedAt },
      })
        .sort({ sentAt: -1 })
        .populate("leadId", "email")
        .limit(100);
      const delivery = candidates.find(
        (item) => normalizeEmail(item.leadId?.email) === from,
      );
      if (!delivery) continue;

      const result = await SEQUENCE_DELIVERY.updateOne(
        { _id: delivery._id, repliedAt: null },
        {
          $set: {
            repliedAt: receivedAt,
            replyMessageId: `zoho:${messageId}`,
            replyFrom: from,
            replySubject: String(message.subject || "").slice(0, 500),
            replySnippet: String(message.summary || message.snippet || "").slice(0, 500),
          },
        },
      );
      if (result.modifiedCount === 1) replied += 1;
    }

    await ZOHO_INTEGRATION.updateOne(
      { _id: locked._id },
      { $set: { lastSyncAt: syncStartedAt, syncLockUntil: null, lastSyncError: null } },
    );
    return { checked: messages.length, replied };
  } catch (error) {
    await ZOHO_INTEGRATION.updateOne(
      { _id: locked._id },
      { $set: { syncLockUntil: null, lastSyncError: String(error.message || error) } },
    );
    throw error;
  }
}

async function syncAllZohoReplies() {
  const integrations = await ZOHO_INTEGRATION.find({});
  let processed = 0;
  let replies = 0;
  for (const integration of integrations) {
    try {
      const result = await syncZohoReplies(integration);
      if (!result.skipped) processed += 1;
      replies += result.replied || 0;
    } catch (error) {
      console.error(`Zoho reply sync failed for ${integration.email}:`, error.message);
    }
  }
  return { found: integrations.length, processed, replies };
}

module.exports = { zohoGet, syncZohoReplies, syncAllZohoReplies };
