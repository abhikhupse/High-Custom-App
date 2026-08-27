const { google } = require("googleapis");

const GMAIL_INTEGRATION = require("../model/gmail_integration.model");

const createGoogleOAuthClient = require("../config/google_oauth");

const {
  buildSequenceEmail,
  replaceLeadPlaceholders,
} = require("../templates/sequenceEmail.template");

const SENDER_COPY_LABEL_NAME = "High Custom Sequences";

// Cache label IDs per connected Gmail account for the lifetime of the server.
const senderCopyLabelCache = new Map();
const senderCopyLabelPromiseCache = new Map();

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

  try {
    await gmail.users.messages.trash({
      userId: "me",
      id: messageId,
    });

    console.log("SENDER COPY MOVED TO GMAIL TRASH");
    console.log("Message ID:", messageId);
  } catch (trashError) {
    console.error("SENDER COPY COULD NOT BE MOVED TO TRASH");
    console.error(
      "Reason:",
      trashError?.response?.data?.error?.message ||
        trashError?.message ||
        "Unknown Gmail trash error",
    );
  }
}

// ============================================================
// BASE64 URL ENCODE
// ============================================================

function encodeBase64Url(input) {
  return Buffer.from(input)
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
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
// CREATE MIME MESSAGE
// ============================================================

function createMimeMessage({ from, to, subject, html }) {
  const message = [
    `From: ${from}`,
    `To: ${to}`,
    `Subject: ${subject}`,
    "MIME-Version: 1.0",
    "Content-Type: text/html; charset=UTF-8",
    "",
    html,
  ].join("\r\n");

  return encodeBase64Url(message);
}

// ============================================================
// DETECT EMAIL FAILURE TYPE
// ============================================================

function getFailureType(error) {
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

  error.failureReason = failureReason || message || "Email sending failed";

  return error;
}

// ============================================================
// SEND SEQUENCE EMAIL
// ============================================================

async function sendSequenceEmail({
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

  const html = buildSequenceEmail({
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

  const raw = createMimeMessage({
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

  // Labeling and trashing only affect the sender-side Gmail copy. Run those
  // operations after the recipient delivery has already been confirmed so
  // they do not delay the next campaign email.
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

// ============================================================
// EXPORT
// ============================================================

module.exports = {
  sendSequenceEmail,
  isValidEmail,
  getFailureType,
};
