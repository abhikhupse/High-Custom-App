const { buildSequenceText } = require("../utils/emailMessage");
const axios = require("axios");

const ZOHO_INTEGRATION = require("../model/zoho_integration.model");
const {
  buildSequenceEmail,
  replaceLeadPlaceholders,
} = require("../templates/sequenceEmail.template");

// One worker can process many emails for the same user concurrently. Sharing
// the refresh promise prevents a burst from refreshing the same token once per
// email when it expires.
const refreshPromises = new Map();

function accountsBaseUrl() {
  return String(
    process.env.ZOHO_ACCOUNTS_BASE_URL || "https://accounts.zoho.in",
  ).replace(/\/$/, "");
}

function mailBaseUrl() {
  return String(
    process.env.ZOHO_MAIL_BASE_URL || "https://mail.zoho.in",
  ).replace(/\/$/, "");
}

function zohoErrorDetail(error) {
  const payload = error?.response?.data;
  return (
    payload?.data?.moreInfo ||
    payload?.status?.description ||
    payload?.error_description ||
    payload?.error ||
    payload?.message ||
    error?.message ||
    "Zoho Mail failed to send email."
  );
}

function classifyZohoError(error) {
  const status = Number(error?.response?.status || 0);
  const message = String(zohoErrorDetail(error)).toLowerCase();

  if (
    status === 401 ||
    message.includes("invalid oauth") ||
    message.includes("invalid_grant") ||
    message.includes("invalid token") ||
    message.includes("invalid_client")
  ) {
    return { failureType: "authentication_error", retryable: false };
  }
  if (status === 403 || message.includes("scope") || message.includes("permission")) {
    return { failureType: "permission_error", retryable: false };
  }
  if (status === 429 || status >= 500) {
    return { failureType: "temporary_failure", retryable: true };
  }
  if (status >= 400 && status < 500) {
    return { failureType: "invalid_recipient", retryable: false };
  }
  return { failureType: "temporary_failure", retryable: true };
}

function createZohoError(error) {
  const detail = zohoErrorDetail(error);
  const classification = classifyZohoError(error);
  const wrapped = new Error(detail);
  wrapped.failureType = classification.failureType;
  wrapped.failureReason = detail;
  wrapped.retryable = classification.retryable;
  wrapped.provider = "zoho";
  wrapped.statusCode = error?.response?.status || null;
  return wrapped;
}

async function refreshAccessToken(integration, force = false) {
  if (
    !force &&
    integration.accessToken &&
    integration.expiresAt &&
    new Date(integration.expiresAt).getTime() > Date.now() + 60_000
  ) {
    return integration.accessToken;
  }

  if (!integration.refreshToken) {
    const error = new Error("Zoho refresh token is missing. Please reconnect Zoho Mail.");
    error.failureType = "authentication_error";
    error.failureReason = error.message;
    error.retryable = false;
    throw error;
  }

  const key = String(integration._id || integration.userId);
  const pending = refreshPromises.get(key);
  if (pending) return pending;

  const refreshPromise = (async () => {
    try {
      const body = new URLSearchParams({
        refresh_token: integration.refreshToken,
        client_id: process.env.ZOHO_CLIENT_ID || "",
        client_secret: process.env.ZOHO_CLIENT_SECRET || "",
        grant_type: "refresh_token",
      });
      const response = await axios.post(
        `${accountsBaseUrl()}/oauth/v2/token`,
        body,
        { headers: { "Content-Type": "application/x-www-form-urlencoded" } },
      );
      const token = response.data?.access_token;
      if (!token) throw new Error(response.data?.error || "Zoho token refresh failed.");

      integration.accessToken = token;
      integration.expiresAt = new Date(
        Date.now() + Number(response.data.expires_in || 3600) * 1000,
      );
      await integration.save();
      return token;
    } catch (error) {
      throw createZohoError(error);
    }
  })();

  refreshPromises.set(key, refreshPromise);
  try {
    return await refreshPromise;
  } finally {
    refreshPromises.delete(key);
  }
}

async function postZohoMessage(integration, payload, forceRefresh = false) {
  const accessToken = await refreshAccessToken(integration, forceRefresh);
  return axios.post(
    `${mailBaseUrl()}/api/accounts/${encodeURIComponent(integration.accountId)}/messages`,
    payload,
    {
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: `Zoho-oauthtoken ${accessToken}`,
      },
    },
  );
}

async function sendZohoSequenceEmail({
  integration,
  sequence,
  lead,
  trackingUrl,
  interestedUrl,
  notInterestedUrl,
  baseUrl,
  onAccepted,
}) {
  const html = buildSequenceEmail({
    sequence,
    lead,
    trackingUrl,
    interestedUrl,
    notInterestedUrl,
    baseUrl,
  });
  const payload = {
    fromAddress: integration.email,
    toAddress: lead.email,
    subject: replaceLeadPlaceholders(sequence.subject || "", lead),
    content: process.env.EMAIL_ZOHO_PLAIN_TEXT === "true"
      ? buildSequenceText({ sequence, lead, notInterestedUrl, baseUrl }) : html,
    mailFormat: process.env.EMAIL_ZOHO_PLAIN_TEXT === "true" ? "plaintext" : "html",
    encoding: "UTF-8",
  };

  console.log("ZOHO SEND STARTED", {
    userId: String(integration.userId),
    to: lead.email,
  });

  let response;
  try {
    response = await postZohoMessage(integration, payload);
  } catch (error) {
    // An access token can be revoked shortly before its stored expiry. Refresh
    // once and replay only when Zoho explicitly rejected authentication.
    if (Number(error?.response?.status) === 401) {
      try {
        response = await postZohoMessage(integration, payload, true);
      } catch (retryError) {
        throw createZohoError(retryError);
      }
    } else {
      throw createZohoError(error);
    }
  }

  const body = response?.data || {};
  const statusCode = Number(body?.status?.code || response?.status || 0);
  if (statusCode >= 400 || body?.status?.description === "failure") {
    throw createZohoError({ response: { status: statusCode, data: body } });
  }

  const messageId = String(
    body?.data?.messageId || body?.data?.messageID || body?.messageId || "",
  );
  if (!messageId) {
    const error = new Error("Zoho accepted the request but returned no message ID.");
    error.failureType = "unknown";
    error.failureReason = error.message;
    // Do not replay an accepted request: doing so can duplicate the email.
    error.retryable = false;
    throw error;
  }

  if (typeof onAccepted === "function") {
    await onAccepted({ messageId: `zoho:${messageId}`, threadId: null });
  }

  console.log("EMAIL ACCEPTED BY ZOHO", { to: lead.email, messageId });
  return {
    success: true,
    provider: "zoho",
    messageId: `zoho:${messageId}`,
    threadId: null,
    from: integration.email,
    to: lead.email,
    status: "sent",
  };
}

async function findZohoIntegration(userId) {
  return ZOHO_INTEGRATION.findOne({ userId });
}

module.exports = {
  findZohoIntegration,
  sendZohoSequenceEmail,
  _private: { refreshAccessToken, classifyZohoError, postZohoMessage },
};
