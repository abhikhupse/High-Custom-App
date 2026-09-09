const { createMimeMessage, buildSequenceBodies } = require("../utils/emailMessage");
const { google } = require("googleapis");
const { promises: dns } = require("node:dns");

const GMAIL_INTEGRATION = require("../model/gmail_integration.model");
const {
  findZohoIntegration,
  sendZohoSequenceEmail,
} = require("./zoho_email.service");
const {
  findGoDaddyIntegration,
  sendGoDaddySequenceEmail,
} = require("./godaddy_email.service");

const createGoogleOAuthClient = require("../config/google_oauth");

const {
  replaceLeadPlaceholders,
} = require("../templates/sequenceEmail.template");

const SENDER_COPY_LABEL_NAME = "High Custom Sequences";
const PROVIDER_LOOKUP_CACHE_TTL_MS = 6 * 60 * 60 * 1000;

// Cache label IDs per connected Gmail account for the lifetime of the server.
const senderCopyLabelCache = new Map();
const senderCopyLabelPromiseCache = new Map();
const recipientProviderCache = new Map();

function recipientDomain(email) {
  const normalized = String(email || "").trim().toLowerCase();
  const separator = normalized.lastIndexOf("@");
  return separator > 0 ? normalized.slice(separator + 1) : "";
}

function providerFromDomain(domain) {
  if (["gmail.com", "googlemail.com"].includes(domain)) return "gmail";
  if (
    domain === "zoho.com" ||
    domain === "zohomail.com" ||
    domain.startsWith("zohomail.")
  ) {
    return "zoho";
  }
  return null;
}

function providerFromMxRecords(records) {
  const hosts = records
    .map((record) => String(record.exchange || "").toLowerCase())
    .join(" ");

  if (/googlemail|aspmx\.l\.google\.com|\.google\.com/.test(hosts)) {
    return "gmail";
  }
  if (/zoho\.com|zoho\.(eu|in|com\.au)/.test(hosts)) return "zoho";
  if (/titan\.email|secureserver\.net|godaddy/.test(hosts)) {
    return "godaddy";
  }
  return null;
}

// Personal addresses can be recognized immediately. For custom-domain leads,
// inspect MX records so Google Workspace, Zoho Mail, and GoDaddy/Titan inboxes
// get the matching sender whenever that integration is available.
async function preferredProviderForRecipient(email) {
  const domain = recipientDomain(email);
  if (!domain) return null;

  const directProvider = providerFromDomain(domain);
  if (directProvider) return directProvider;

  const cached = recipientProviderCache.get(domain);
  if (cached && cached.expiresAt > Date.now()) return cached.provider;

  let provider = null;
  try {
    provider = providerFromMxRecords(await dns.resolveMx(domain));
  } catch (_) {
    // Normal fallback selection below still delivers through the most recently
    // connected provider when MX records cannot be resolved.
  }

  recipientProviderCache.set(domain, {
    provider,
    expiresAt: Date.now() + PROVIDER_LOOKUP_CACHE_TTL_MS,
  });
  return provider;
}

async function getOrCreateSenderCopyLabel(gmail, accountEmail) {
  const cachedLabelId = senderCopyLabelCache.get(accountEmail);

  if (cachedLabelId) {
    return cachedLabelId;
  }

  const pendingPromise = senderCopyLabelPromiseCache.get(accountEmail);

  if (pendingPromise) {
    return pendingPromise;
  }

  const labelPromise = resolveSenderCopyLabel(gmail, accountEmail);
  senderCopyLabelPromiseCache.set(accountEmail, labelPromise);

  try {
    return await labelPromise;
  } finally {
    senderCopyLabelPromiseCache.delete(accountEmail);
  }
}

async function resolveSenderCopyLabel(gmail, accountEmail) {
  const cachedLabelId = senderCopyLabelCache.get(accountEmail);

  if (cachedLabelId) {
    return cachedLabelId;
  }

  const labelsResponse = await gmail.users.labels.list({
    userId: "me",
  });

  const existingLabel = (labelsResponse.data.labels || []).find(
    (label) =>
      label.type === "user" && label.name === SENDER_COPY_LABEL_NAME,
  );

  if (existingLabel?.id) {
    senderCopyLabelCache.set(accountEmail, existingLabel.id);
    return existingLabel.id;
  }

  const createResponse = await gmail.users.labels.create({
    userId: "me",
    requestBody: {
      name: SENDER_COPY_LABEL_NAME,
      labelListVisibility: "labelShow",
      messageListVisibility: "show",
    },
  });

  const labelId = createResponse.data.id;

  if (!labelId) {
    throw new Error("Gmail did not return the created label ID.");
  }

  senderCopyLabelCache.set(accountEmail, labelId);

  return labelId;
}

async function processSenderCopy({ gmail, messageId, labelId, accountEmail }) {
  try {
    await gmail.users.messages.modify({
      userId: "me",
      id: messageId,
      requestBody: {
        addLabelIds: [labelId],
      },
    });

    console.log("CUSTOM LABEL APPLIED TO SENDER COPY");
    console.log("Label:", SENDER_COPY_LABEL_NAME);
    console.log("Message ID:", messageId);
  } catch (labelError) {
    senderCopyLabelCache.delete(accountEmail);

    console.error("CUSTOM LABEL COULD NOT BE APPLIED TO SENDER COPY");
    console.error(
      "Reason:",
      labelError?.response?.data?.error?.message ||
        labelError?.message ||
        "Unknown Gmail label error",
    );
  }

  // Keep the Gmail SENT copy intact. Moving it to Trash immediately after
  // users.messages.send can race Gmail's asynchronous recipient delivery and
  // has caused accepted messages to never appear in the recipient mailbox.
}

// ============================================================
// EMAIL VALIDATION
// ============================================================

function isValidEmail(email) {
  if (!email || typeof email !== "string") {
    return false;
  }

  const normalizedEmail = email.trim();

  // Basic email validation
  const emailRegex =
    /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/;

  return emailRegex.test(normalizedEmail);
}

// ============================================================
// DETECT EMAIL FAILURE TYPE
// ============================================================

function getFailureType(error) {
  const status = Number(error?.response?.status || error?.code || 0);
  if (status === 429 || status >= 500) return "temporary_failure";
  const response = error?.response?.data;

  const message =
    response?.error?.message || response?.message || error?.message || "";

  const lowerMessage = String(message).toLowerCase();

  // ==========================================================
  // INVALID RECIPIENT
  // ==========================================================

  if (
    lowerMessage.includes("invalid recipient") ||
    lowerMessage.includes("invalid email") ||
    lowerMessage.includes("recipient address") ||
    lowerMessage.includes("bad address") ||
    lowerMessage.includes("invalid argument") ||
    lowerMessage.includes("malformed") ||
    lowerMessage.includes("email address")
  ) {
    return "invalid_recipient";
  }

  // ==========================================================
  // INVALID DOMAIN
  // ==========================================================

  if (
    lowerMessage.includes("domain") &&
    (lowerMessage.includes("not found") ||
      lowerMessage.includes("invalid") ||
      lowerMessage.includes("does not exist"))
  ) {
    return "invalid_domain";
  }

  // ==========================================================
  // MAILBOX FULL
  // ==========================================================

  if (
    lowerMessage.includes("mailbox full") ||
    lowerMessage.includes("quota exceeded") ||
    lowerMessage.includes("over quota") ||
    lowerMessage.includes("storage quota")
  ) {
    return "mailbox_full";
  }

  // ==========================================================
  // BLOCKED / REJECTED
  // ==========================================================

  if (
    lowerMessage.includes("blocked") ||
    lowerMessage.includes("rejected") ||
    lowerMessage.includes("not accepted") ||
    lowerMessage.includes("denied")
  ) {
    return "blocked";
  }

  // ==========================================================
  // TEMPORARY FAILURE
  // ==========================================================

  if (
    lowerMessage.includes("temporarily") ||
    lowerMessage.includes("try again later") ||
    lowerMessage.includes("temporary failure") ||
    lowerMessage.includes("rate limit") ||
    lowerMessage.includes("too many requests")
  ) {
    return "temporary_failure";
  }

  // ==========================================================
  // AUTHENTICATION
  // ==========================================================

  if (
    lowerMessage.includes("unauthorized") ||
    lowerMessage.includes("invalid authentication") ||
    lowerMessage.includes("invalid credentials") ||
    lowerMessage.includes("authentication")
  ) {
    return "authentication_error";
  }

  // ==========================================================
  // PERMISSION
  // ==========================================================

  if (
    lowerMessage.includes("permission") ||
    lowerMessage.includes("forbidden") ||
    lowerMessage.includes("insufficient")
  ) {
    return "permission_error";
  }

  // ==========================================================
  // DEFAULT
  // ==========================================================

  return "unknown";
}

// ============================================================
// CREATE STRUCTURED ERROR
// ============================================================

function createEmailError({ message, failureType, failureReason }) {
  const error = new Error(message || failureReason || "Email sending failed");

  error.failureType = failureType || "unknown";
  error.retryable = failureType === "temporary_failure";

  error.failureReason = failureReason || message || "Email sending failed";

  return error;
}

// ============================================================
// SEND SEQUENCE EMAIL
// ============================================================

async function sendGmailSequenceEmail({
  userId,
  sequence,
  lead,
  trackingUrl,
  interestedUrl,
  notInterestedUrl,
  baseUrl,
  onAccepted,
}) {
  console.log("==============================================");
  console.log("GMAIL SEND STARTED");
  console.log("USER:", userId);
  console.log("LEAD:", lead?.email);
  console.log("==============================================");

  // ==========================================================
  // CHECK LEAD EMAIL
  // ==========================================================

  const leadEmail = typeof lead?.email === "string" ? lead.email.trim() : "";

  if (!leadEmail) {
    const error = createEmailError({
      message: "Lead email address is missing.",
      failureType: "invalid_recipient",
      failureReason: "Lead email address is missing.",
    });

    console.error("INVALID RECIPIENT:", error.failureReason);

    throw error;
  }

  // ==========================================================
  // VALIDATE EMAIL FORMAT
  // ==========================================================

  if (!isValidEmail(leadEmail)) {
    const error = createEmailError({
      message: `Invalid email address: ${leadEmail}`,
      failureType: "invalid_recipient",
      failureReason: `Invalid email address: ${leadEmail}`,
    });

    console.error("==============================================");
    console.error("INVALID EMAIL ADDRESS");
    console.error("TO:", leadEmail);
    console.error("TYPE:", error.failureType);
    console.error("REASON:", error.failureReason);
    console.error("==============================================");

    throw error;
  }

  // ==========================================================
  // GET GMAIL INTEGRATION
  // ==========================================================

  const integration = await GMAIL_INTEGRATION.findOne({
    userId,
  });

  if (!integration) {
    const error = createEmailError({
      message: "Gmail is not connected for this user.",
      failureType: "gmail_not_connected",
      failureReason: "Gmail is not connected for this user.",
    });

    throw error;
  }

  console.log("Gmail account:", integration.email);

  // ==========================================================
  // REFRESH TOKEN REQUIRED
  // ==========================================================

  if (!integration.refreshToken) {
    const error = createEmailError({
      message: "Gmail refresh token is missing. Please reconnect Gmail.",
      failureType: "authentication_error",
      failureReason: "Gmail refresh token is missing. Please reconnect Gmail.",
    });

    throw error;
  }

  // ==========================================================
  // CREATE OAUTH CLIENT
  // ==========================================================

  const oauth2Client = createGoogleOAuthClient();

  oauth2Client.setCredentials({
    refresh_token: integration.refreshToken,
  });

  // ==========================================================
  // GET ACCESS TOKEN
  // ==========================================================

  let accessToken;

  try {
    const tokenResponse = await oauth2Client.getAccessToken();

    accessToken = tokenResponse?.token;
  } catch (error) {
    console.error("GMAIL TOKEN ERROR:", error.response?.data || error.message);

    const failureReason =
      error.response?.data?.error?.message ||
      error.message ||
      "Unable to refresh Gmail access token.";

    throw createEmailError({
      message: failureReason,
      failureType: "authentication_error",
      failureReason,
    });
  }

  if (!accessToken) {
    throw createEmailError({
      message: "Unable to get Gmail access token. Please reconnect Gmail.",
      failureType: "authentication_error",
      failureReason:
        "Unable to get Gmail access token. Please reconnect Gmail.",
    });
  }

  // ==========================================================
  // SET ACCESS TOKEN
  // ==========================================================

  oauth2Client.setCredentials({
    refresh_token: integration.refreshToken,
    access_token: accessToken,
  });

  // ==========================================================
  // BUILD HTML
  // ==========================================================

  const { text, html } = buildSequenceBodies({
    sequence,
    lead: {
      ...lead,
      email: leadEmail,
    },
    trackingUrl,
    interestedUrl,
    notInterestedUrl,
    baseUrl,
  });

  // ==========================================================
  // CREATE MIME
  // ==========================================================

  const raw = await createMimeMessage({
    text,
    from: integration.email,
    to: leadEmail,
    subject: replaceLeadPlaceholders(sequence.subject || "", lead),
    html,
  });

  // ==========================================================
  // CREATE GMAIL CLIENT
  // ==========================================================

  const gmail = google.gmail({
    version: "v1",
    auth: oauth2Client,
  });

  // ==========================================================
  // SEND EMAIL
  // ==========================================================

  let response;

  try {
    response = await gmail.users.messages.send({
      userId: "me",

      requestBody: {
        raw,
      },
    });
  } catch (error) {
    const gmailError = error?.response?.data || {};

    const failureReason =
      gmailError?.error?.message ||
      gmailError?.message ||
      error?.message ||
      "Gmail failed to send email.";

    const failureType = getFailureType(error);

    console.error("==============================================");
    console.error("GMAIL SEND FAILED");
    console.error("TO:", leadEmail);
    console.error("TYPE:", failureType);
    console.error("REASON:", failureReason);
    console.error("==============================================");

    throw createEmailError({
      message: failureReason,
      failureType,
      failureReason,
    });
  }

  // ==========================================================
  // VERIFY GMAIL RESPONSE
  // ==========================================================

  if (!response?.data?.id) {
    const error = createEmailError({
      message:
        "Gmail did not return a message ID. Email was not confirmed as sent.",
      failureType: "unknown",
      failureReason:
        "Gmail did not return a message ID. Email was not confirmed as sent.",
    });

    throw error;
  }

  // ==========================================================
  // CONFIRM DELIVERY IMMEDIATELY AFTER GMAIL ACCEPTS IT
  // ==========================================================

  if (typeof onAccepted === "function") {
    await onAccepted({
      messageId: response.data.id,
      threadId: response.data.threadId || null,
    });
  }

  // ==========================================================
  // APPLY CUSTOM LABEL TO THE SENDER-SIDE COPY
  // ==========================================================
  //
  // The recipient has already received the message. This operation only
  // changes the copy in the connected sender's Gmail mailbox. A trash
  // failure must not mark the delivery as failed or retry the send, because
  // that could deliver a duplicate email to the recipient.
  // ==========================================================

  let senderCopyLabelId = null;

  try {
    senderCopyLabelId = await getOrCreateSenderCopyLabel(
      gmail,
      integration.email,
    );
  } catch (labelError) {
    senderCopyLabelCache.delete(integration.email);

    console.error("CUSTOM LABEL COULD NOT BE PREPARED");
    console.error(
      "Reason:",
      labelError?.response?.data?.error?.message ||
        labelError?.message ||
        "Unknown Gmail label error",
    );
  }

  // ==========================================================
  // SAVE NEW ACCESS TOKEN
  // ==========================================================

  if (oauth2Client.credentials.access_token) {
    integration.accessToken = oauth2Client.credentials.access_token;
  }

  // ==========================================================
  // SAVE TOKEN EXPIRY
  // ==========================================================

  if (oauth2Client.credentials.expiry_date) {
    integration.expiryDate = oauth2Client.credentials.expiry_date;
  }

  await integration.save();

  // Label the sender-side Gmail copy without deleting/trashing it.
  if (senderCopyLabelId) {
    setImmediate(() => {
      processSenderCopy({
        gmail,
        messageId: response.data.id,
        labelId: senderCopyLabelId,
        accountEmail: integration.email,
      }).catch((backgroundError) => {
        console.error(
          "SENDER COPY BACKGROUND PROCESSING FAILED:",
          backgroundError,
        );
      });
    });
  }

  // ==========================================================
  // SUCCESS
  // ==========================================================

  console.log("==============================================");
  console.log("EMAIL ACCEPTED BY GMAIL");
  console.log("TO:", leadEmail);
  console.log("Message ID:", response.data.id);
  console.log("Thread ID:", response.data.threadId);
  console.log("==============================================");

  return {
    success: true,

    messageId: response.data.id,

    threadId: response.data.threadId,

    from: integration.email,

    to: leadEmail,

    status: "sent",

    senderCopyProcessing: Boolean(senderCopyLabelId),
  };
}

// Prefer the integration connected most recently. This gives users a
// deterministic way to switch providers without adding a second setting: the
// provider they most recently authorized becomes the sender.
async function sendSequenceEmail(options) {
  const [zohoIntegration, gmailIntegration, goDaddyIntegration] = await Promise.all([
    findZohoIntegration(options.userId),
    GMAIL_INTEGRATION.findOne({
      userId: options.userId,
      reconnectRequiredAt: null,
    }),
    findGoDaddyIntegration(options.userId, true),
  ]);

  const zohoScope = String(zohoIntegration?.scope || "");
  const zohoCanSend =
    zohoScope.includes("ZohoMail.messages.CREATE") ||
    zohoScope.includes("ZohoMail.messages.ALL");
  const gmailCanSend =
    !gmailIntegration?.sendingBlockedUntil ||
    new Date(gmailIntegration.sendingBlockedUntil).getTime() <= Date.now();

  const providers = [
    zohoIntegration && zohoCanSend && {
      name: "zoho",
      integration: zohoIntegration,
      connectedAt: zohoIntegration.connectedAt || zohoIntegration.updatedAt,
    },
    gmailIntegration && gmailCanSend && {
      name: "gmail",
      integration: gmailIntegration,
      connectedAt: gmailIntegration.connectedAt || gmailIntegration.updatedAt,
    },
    goDaddyIntegration && {
      name: "godaddy",
      integration: goDaddyIntegration,
      connectedAt:
        goDaddyIntegration.connectedAt || goDaddyIntegration.updatedAt,
    },
  ]
    .filter(Boolean)
    .sort(
      (left, right) =>
        new Date(right.connectedAt || 0).getTime() -
        new Date(left.connectedAt || 0).getTime(),
    );

  const selected = providers[0];
  const recipientProvider = await preferredProviderForRecipient(
    options?.lead?.email,
  );
  const matchedProvider = recipientProvider
    ? providers.find((provider) => provider.name === recipientProvider)
    : null;
  const senderProvider = matchedProvider || selected;

  if (matchedProvider) {
    console.log(
      `EMAIL PROVIDER MATCHED TO RECIPIENT: ${recipientProvider.toUpperCase()}`,
    );
  } else if (recipientProvider && selected) {
    console.log(
      `RECIPIENT PROVIDER ${recipientProvider.toUpperCase()} IS UNAVAILABLE; ` +
        `FALLING BACK TO ${selected.name.toUpperCase()}`,
    );
  }

  if (senderProvider?.name === "zoho") {
      const zohoScope = String(zohoIntegration.scope || "");
      if (
        !zohoScope.includes("ZohoMail.messages.CREATE") &&
        !zohoScope.includes("ZohoMail.messages.ALL")
      ) {
        const error = createEmailError({
          message:
            "Zoho Mail was connected without send permission. Disconnect and reconnect Zoho Mail.",
          failureType: "permission_error",
          failureReason:
            "Zoho Mail was connected without send permission. Disconnect and reconnect Zoho Mail.",
        });
        error.retryable = false;
        throw error;
      }

      console.log("EMAIL PROVIDER SELECTED: ZOHO");
      return sendZohoSequenceEmail({
        ...options,
        integration: zohoIntegration,
      });
  }

  if (senderProvider?.name === "gmail") {
    console.log("EMAIL PROVIDER SELECTED: GMAIL");
    return sendGmailSequenceEmail(options);
  }

  if (senderProvider?.name === "godaddy") {
    console.log("EMAIL PROVIDER SELECTED: GODADDY");
    return sendGoDaddySequenceEmail({
      ...options,
      integration: goDaddyIntegration,
    });
  }

  if (gmailIntegration && !gmailCanSend) {
    const error = createEmailError({
      message:
        "Gmail has temporarily stopped sending because this account reached its sending limit. Wait for Gmail to reset the quota or connect another sender.",
      failureType: "provider_sending_limit",
      failureReason:
        "Gmail sending limit reached. Wait for Gmail to reset the quota or connect another sender.",
    });
    error.retryable = true;
    throw error;
  }

  const error = createEmailError({
    message:
      "No email provider is connected. Connect Gmail, Zoho Mail, or GoDaddy Email.",
    failureType: "email_provider_not_connected",
    failureReason:
      "No email provider is connected. Connect Gmail, Zoho Mail, or GoDaddy Email.",
  });
  error.retryable = false;
  throw error;
}

// ============================================================
// EXPORT
// ============================================================

module.exports = {
  sendSequenceEmail,
  isValidEmail,
  getFailureType,
  _private: {
    recipientDomain,
    providerFromDomain,
    providerFromMxRecords,
    preferredProviderForRecipient,
  },
};
