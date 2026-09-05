const { google } = require("googleapis");

const createGoogleOAuthClient = require("../config/google_oauth");
const GMAIL_INTEGRATION = require("../model/gmail_integration.model");
const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");

const activeSyncs = new Set();
const LOCK_DURATION_MS = 2 * 60 * 1000;

function normalizeEmail(value) {
  const text = String(value || "").trim().toLowerCase();
  const angleMatch = text.match(/<([^<>\s]+@[^<>\s]+)>/);

  if (angleMatch) return angleMatch[1].trim();

  const addressMatch = text.match(/[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9.-]+/i);
  return addressMatch ? addressMatch[0].toLowerCase() : "";
}

function headerMap(message) {
  const headers = message?.payload?.headers || [];

  return new Map(
    headers.map((header) => [
      String(header.name || "").toLowerCase(),
      String(header.value || ""),
    ]),
  );
}

function isAutomatedReply(headers, from, subject) {
  const autoSubmitted = String(headers.get("auto-submitted") || "").toLowerCase();
  const precedence = String(headers.get("precedence") || "").toLowerCase();
  const autoResponseSuppress = headers.get("x-auto-response-suppress");
  const sender = String(from || "").toLowerCase();
  const normalizedSubject = String(subject || "").trim().toLowerCase();

  return (
    (autoSubmitted && autoSubmitted !== "no") ||
    ["bulk", "junk", "list"].includes(precedence) ||
    Boolean(autoResponseSuppress) ||
    sender.startsWith("mailer-daemon@") ||
    sender.startsWith("postmaster@") ||
    normalizedSubject.startsWith("automatic reply:") ||
    normalizedSubject.startsWith("auto reply:") ||
    normalizedSubject.startsWith("out of office:")
  );
}

async function authenticatedGmail(integration) {
  const oauth2Client = createGoogleOAuthClient();

  oauth2Client.setCredentials({
    access_token: integration.accessToken,
    refresh_token: integration.refreshToken,
    expiry_date: integration.expiryDate,
    token_type: integration.tokenType || "Bearer",
  });

  return {
    gmail: google.gmail({ version: "v1", auth: oauth2Client }),
    oauth2Client,
  };
}

async function persistRefreshedCredentials(integration, oauth2Client) {
  const accessToken = oauth2Client.credentials.access_token;
  const expiryDate = oauth2Client.credentials.expiry_date;

  if (
    (accessToken && accessToken !== integration.accessToken) ||
    (expiryDate && expiryDate !== integration.expiryDate)
  ) {
    await GMAIL_INTEGRATION.updateOne(
      { _id: integration._id },
      {
        $set: {
          ...(accessToken ? { accessToken } : {}),
          ...(expiryDate ? { expiryDate } : {}),
        },
      },
    );
  }
}

async function registerGmailWatch(integration) {
  const topicName = String(process.env.GMAIL_PUBSUB_TOPIC || "").trim();

  if (!topicName) {
    return { enabled: false, reason: "GMAIL_PUBSUB_TOPIC is not configured." };
  }

  const { gmail, oauth2Client } = await authenticatedGmail(integration);
  const response = await gmail.users.watch({
    userId: "me",
    requestBody: {
      topicName,
      labelIds: ["INBOX"],
      labelFilterBehavior: "INCLUDE",
    },
  });

  const historyId = response.data.historyId
    ? String(response.data.historyId)
    : integration.lastHistoryId;
  const expiration = response.data.expiration
    ? new Date(Number(response.data.expiration))
    : null;

  await GMAIL_INTEGRATION.updateOne(
    { _id: integration._id },
    {
      $set: {
        ...(!integration.lastHistoryId && historyId
          ? { lastHistoryId: historyId }
          : {}),
        watchExpiration: expiration,
        watchLastRenewedAt: new Date(),
        replySyncLastError: null,
      },
    },
  );

  await persistRefreshedCredentials(integration, oauth2Client);

  return { enabled: true, historyId, expiration };
}

async function processInboundMessage({ gmail, integration, messageId }) {
  const existing = await SEQUENCE_DELIVERY.exists({
    userId: integration.userId,
    replyMessageId: messageId,
  });

  if (existing) return { outcome: "duplicate" };

  const response = await gmail.users.messages.get({
    userId: "me",
    id: messageId,
    format: "metadata",
    metadataHeaders: [
      "From",
      "To",
      "Subject",
      "Auto-Submitted",
      "Precedence",
      "X-Auto-Response-Suppress",
    ],
  });

  const message = response.data;
  const labels = new Set(message.labelIds || []);

  if (!labels.has("INBOX") || labels.has("SENT") || labels.has("DRAFT")) {
    return { outcome: "not_inbound" };
  }

  const headers = headerMap(message);
  const from = normalizeEmail(headers.get("from"));
  const subject = headers.get("subject") || "";

  if (!from || from === normalizeEmail(integration.email)) {
    return { outcome: "own_message" };
  }

  if (isAutomatedReply(headers, from, subject)) {
    if (/^(mailer-daemon|postmaster)@/i.test(from)) {
      const full = await gmail.users.messages.get({ userId: "me", id: messageId, format: "full" });
      const { permanentFailures } = require("../utils/deliveryStatus");
      const SUPPRESSION = require("../model/email_suppression.model");
      for (const email of permanentFailures(full.data?.payload)) {
        // Require a matching outgoing thread and recipient before suppressing.
        const sent = await SEQUENCE_DELIVERY.exists({
          userId: integration.userId, email, status: "sent",
          threadId: message.threadId,
        });
        if (message.threadId && sent) {
          await SUPPRESSION.updateOne({ userId: integration.userId, email },
            { $setOnInsert: { reason: "hard_bounce" } }, { upsert: true });
        }
      }
    }
    return { outcome: "automated" };
  }

  const repliedAt = message.internalDate
    ? new Date(Number(message.internalDate))
    : new Date();

  const deliveries = await SEQUENCE_DELIVERY.find({
    userId: integration.userId,
    threadId: message.threadId,
    status: "sent",
    repliedAt: null,
    sentAt: { $lte: repliedAt },
  })
    .sort({ sentAt: -1 })
    .populate("leadId", "email")
    .limit(5);

  const delivery = deliveries.find(
    (item) => normalizeEmail(item.leadId?.email) === from,
  );

  if (!delivery) return { outcome: "unmatched" };

  const update = await SEQUENCE_DELIVERY.updateOne(
    {
      _id: delivery._id,
      repliedAt: null,
      replyMessageId: null,
    },
    {
      $set: {
        repliedAt,
        replyMessageId: message.id,
        replyFrom: from,
        replySubject: String(subject).slice(0, 500),
        replySnippet: String(message.snippet || "").slice(0, 500),
      },
    },
  );

  return {
    outcome: update.modifiedCount === 1 ? "replied" : "duplicate",
    deliveryId: delivery._id,
  };
}

async function acquireSyncLock(email) {
  const now = new Date();

  return GMAIL_INTEGRATION.findOneAndUpdate(
    {
      email: normalizeEmail(email),
      $or: [
        { replySyncLockUntil: null },
        { replySyncLockUntil: { $exists: false } },
        { replySyncLockUntil: { $lt: now } },
      ],
    },
    {
      $set: {
        replySyncLockUntil: new Date(now.getTime() + LOCK_DURATION_MS),
      },
    },
    { returnDocument: "after" },
  );
}

async function recordPendingGmailNotification({ emailAddress, historyId }) {
  const email = normalizeEmail(emailAddress);

  if (!email || !historyId) return false;

  const integration = await GMAIL_INTEGRATION.findOne({ email }).select({
    replySyncPendingHistoryId: 1,
  });

  if (!integration) return false;

  let pendingHistoryId = String(historyId);

  try {
    const existing = integration.replySyncPendingHistoryId;
    if (existing && BigInt(existing) > BigInt(pendingHistoryId)) {
      pendingHistoryId = existing;
    }
  } catch (_) {
    // The Gmail API will validate an unexpected history ID during processing.
  }

  await GMAIL_INTEGRATION.updateOne(
    { _id: integration._id },
    { $set: { replySyncPendingHistoryId: pendingHistoryId } },
  );

  return true;
}

async function clearPendingHistoryId(integrationId, historyId) {
  await GMAIL_INTEGRATION.updateOne(
    {
      _id: integrationId,
      replySyncPendingHistoryId: String(historyId),
    },
    { $set: { replySyncPendingHistoryId: null } },
  );
}

async function processGmailNotification({ emailAddress, historyId }) {
  const normalizedEmail = normalizeEmail(emailAddress);

  if (!normalizedEmail || !historyId || activeSyncs.has(normalizedEmail)) {
    return { processed: false, reason: "invalid_or_busy" };
  }

  activeSyncs.add(normalizedEmail);
  let integration;

  try {
    integration = await acquireSyncLock(normalizedEmail);

    if (!integration) return { processed: false, reason: "locked_or_unknown" };

    if (!integration.lastHistoryId) {
      await GMAIL_INTEGRATION.updateOne(
        { _id: integration._id },
        {
          $set: {
            lastHistoryId: String(historyId),
            replySyncLastCompletedAt: new Date(),
            replySyncLockUntil: null,
          },
        },
      );

      await clearPendingHistoryId(integration._id, historyId);

      return { processed: true, initialized: true };
    }

    try {
      if (BigInt(historyId) <= BigInt(integration.lastHistoryId)) {
        await GMAIL_INTEGRATION.updateOne(
          { _id: integration._id },
          {
            $set: {
              replySyncLastCompletedAt: new Date(),
              replySyncLastError: null,
              replySyncLockUntil: null,
            },
          },
        );

        await clearPendingHistoryId(integration._id, historyId);

        return { processed: true, staleNotification: true };
      }
    } catch (_) {
      // Gmail history IDs are decimal strings. If an unexpected value is
      // received, let the Gmail API validate it and record the resulting error.
    }

    const { gmail, oauth2Client } = await authenticatedGmail(integration);
    const messageIds = new Set();
    let pageToken;
    let newestHistoryId = String(historyId);

    try {
      do {
        const response = await gmail.users.history.list({
          userId: "me",
          startHistoryId: integration.lastHistoryId,
          historyTypes: ["messageAdded"],
          labelId: "INBOX",
          pageToken,
          maxResults: 100,
        });

        for (const history of response.data.history || []) {
          for (const added of history.messagesAdded || []) {
            if (added.message?.id) messageIds.add(added.message.id);
          }
        }

        if (response.data.historyId) {
          newestHistoryId = String(response.data.historyId);
        }

        pageToken = response.data.nextPageToken;
      } while (pageToken);
    } catch (error) {
      const status = error?.response?.status || error?.code;

      if (Number(status) !== 404) throw error;

      // Gmail history cursors can expire. Recover by inspecting recent inbox
      // messages instead of permanently leaving reply tracking stuck.
      pageToken = undefined;

      do {
        const response = await gmail.users.messages.list({
          userId: "me",
          q: "in:inbox newer_than:30d",
          pageToken,
          maxResults: 100,
        });

        for (const message of response.data.messages || []) {
          if (message.id) messageIds.add(message.id);
        }

        pageToken = response.data.nextPageToken;
      } while (pageToken);
    }

    const outcomes = {};

    for (const messageId of messageIds) {
      try {
        const result = await processInboundMessage({
          gmail,
          integration,
          messageId,
        });
        outcomes[result.outcome] = (outcomes[result.outcome] || 0) + 1;
      } catch (error) {
        const status = error?.response?.status || error?.code;

        // Gmail history can contain message IDs that are no longer available
        // by the time a push notification is processed. A deleted or stale
        // message must not block the cursor or every newer reply behind it.
        if (Number(status) === 404) {
          outcomes.missing = (outcomes.missing || 0) + 1;
          console.warn(
            `Gmail reply message no longer available; skipping: ${messageId}`,
          );
          continue;
        }

        outcomes.error = (outcomes.error || 0) + 1;
        console.error("Gmail reply message processing failed:", error.message);
      }
    }

    if (outcomes.error) {
      throw new Error(
        `${outcomes.error} Gmail message(s) could not be processed.`,
      );
    }

    await GMAIL_INTEGRATION.updateOne(
      { _id: integration._id },
      {
        $set: {
          lastHistoryId: newestHistoryId,
          replySyncLastCompletedAt: new Date(),
          replySyncLastError: null,
          replySyncLockUntil: null,
        },
      },
    );

    await clearPendingHistoryId(integration._id, historyId);

    await persistRefreshedCredentials(integration, oauth2Client);

    return { processed: true, messages: messageIds.size, outcomes };
  } catch (error) {
    if (integration?._id) {
      await GMAIL_INTEGRATION.updateOne(
        { _id: integration._id },
        {
          $set: {
            replySyncLockUntil: null,
            replySyncLastError: String(error.message || error).slice(0, 1000),
          },
        },
      ).catch(() => {});
    }

    throw error;
  } finally {
    activeSyncs.delete(normalizedEmail);
  }
}

async function retryPendingGmailNotifications() {
  const integrations = await GMAIL_INTEGRATION.find({
    replySyncPendingHistoryId: { $ne: null },
  })
    .select({ email: 1, replySyncPendingHistoryId: 1 })
    .limit(100)
    .lean();

  let processed = 0;

  for (const integration of integrations) {
    try {
      const result = await processGmailNotification({
        emailAddress: integration.email,
        historyId: integration.replySyncPendingHistoryId,
      });

      if (result.processed) processed++;
    } catch (error) {
      console.error(`Pending Gmail reply sync failed for ${integration.email}:`, error.message);
    }
  }

  return { found: integrations.length, processed };
}

async function renewExpiringGmailWatches() {
  if (!process.env.GMAIL_PUBSUB_TOPIC) return { enabled: false, renewed: 0 };

  const renewalThreshold = new Date(Date.now() + 24 * 60 * 60 * 1000);
  const integrations = await GMAIL_INTEGRATION.find({
    $or: [
      { watchExpiration: null },
      { watchExpiration: { $exists: false } },
      { watchExpiration: { $lte: renewalThreshold } },
    ],
  });

  let renewed = 0;

  for (const integration of integrations) {
    try {
      await registerGmailWatch(integration);
      renewed++;
    } catch (error) {
      console.error(`Gmail watch renewal failed for ${integration.email}:`, error.message);
    }
  }

  return { enabled: true, renewed };
}

module.exports = {
  normalizeEmail,
  registerGmailWatch,
  recordPendingGmailNotification,
  processGmailNotification,
  retryPendingGmailNotifications,
  renewExpiringGmailWatches,
};
