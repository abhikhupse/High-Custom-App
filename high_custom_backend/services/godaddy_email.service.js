const nodemailer = require("nodemailer");

const GODADDY_INTEGRATION = require("../model/godaddy_integration.model");
const { decryptCredential } = require("../utils/credentialCipher");
const { buildSequenceBodies } = require("../utils/emailMessage");
const {
  replaceLeadPlaceholders,
} = require("../templates/sequenceEmail.template");

function smtpConfig(email, password) {
  return {
    host: process.env.GODADDY_SMTP_HOST || "smtpout.secureserver.net",
    port: Number(process.env.GODADDY_SMTP_PORT || 465),
    secure: String(process.env.GODADDY_SMTP_SECURE || "true") !== "false",
    auth: { user: email, pass: password },
    connectionTimeout: 15000,
    greetingTimeout: 15000,
    socketTimeout: 30000,
  };
}

function createGoDaddyTransport(email, password) {
  return nodemailer.createTransport(smtpConfig(email, password));
}

function createGoDaddyError(error) {
  const detail = error?.response || error?.message || "GoDaddy Email failed.";
  const code = String(error?.code || "").toUpperCase();
  const wrapped = new Error(detail);
  wrapped.provider = "godaddy";
  wrapped.failureReason = detail;
  if (code === "EAUTH") {
    wrapped.failureType = "authentication_error";
    wrapped.retryable = false;
  } else if (code === "EENVELOPE") {
    wrapped.failureType = "invalid_recipient";
    wrapped.retryable = false;
  } else {
    wrapped.failureType = "temporary_failure";
    wrapped.retryable = true;
  }
  return wrapped;
}

async function findGoDaddyIntegration(userId, includeCredentials = false) {
  const query = GODADDY_INTEGRATION.findOne({ userId });
  return includeCredentials
    ? query.select("+passwordCiphertext +passwordIv +passwordAuthTag")
    : query;
}

async function sendGoDaddySequenceEmail({
  integration,
  sequence,
  lead,
  trackingUrl,
  interestedUrl,
  notInterestedUrl,
  baseUrl,
  onAccepted,
}) {
  const password = decryptCredential(integration);
  const transporter = createGoDaddyTransport(integration.email, password);
  const { text, html } = buildSequenceBodies({
    sequence,
    lead,
    trackingUrl,
    interestedUrl,
    notInterestedUrl,
    baseUrl,
  });

  let result;
  try {
    result = await transporter.sendMail({
      from: {
        name: integration.senderName || integration.email,
        address: integration.email,
      },
      replyTo: integration.email,
      to: lead.email,
      subject: replaceLeadPlaceholders(sequence.subject || "", lead),
      text,
      html,
    });
  } catch (error) {
    throw createGoDaddyError(error);
  }

  const messageId = String(result?.messageId || "").trim();
  if (!messageId) {
    const error = new Error(
      "GoDaddy accepted the email but returned no message ID.",
    );
    error.provider = "godaddy";
    error.failureType = "unknown";
    error.failureReason = error.message;
    error.retryable = false;
    throw error;
  }

  const providerMessageId = `godaddy:${messageId}`;
  if (typeof onAccepted === "function") {
    await onAccepted({ messageId: providerMessageId, threadId: null });
  }
  return {
    success: true,
    provider: "godaddy",
    messageId: providerMessageId,
    threadId: null,
    from: integration.email,
    to: lead.email,
    status: "sent",
  };
}

module.exports = {
  createGoDaddyTransport,
  findGoDaddyIntegration,
  sendGoDaddySequenceEmail,
  _private: { smtpConfig, createGoDaddyError },
};
