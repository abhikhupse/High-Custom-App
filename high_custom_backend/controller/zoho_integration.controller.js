const axios = require("axios");
const jwt = require("jsonwebtoken");

const ZOHO_INTEGRATION = require("../model/zoho_integration.model");
const { zohoGet, syncZohoReplies } = require("../services/zoho_reply.service");

const APP_DEEP_LINK = "highcustom://integration";

function accountsBaseUrl() {
  return String(
    process.env.ZOHO_ACCOUNTS_BASE_URL || "https://accounts.zoho.in",
  ).replace(/\/$/, "");
}

function requiredConfig() {
  const values = {
    clientId: String(process.env.ZOHO_CLIENT_ID || "").trim(),
    clientSecret: String(process.env.ZOHO_CLIENT_SECRET || "").trim(),
    redirectUri: String(process.env.ZOHO_REDIRECT_URI || "").trim(),
    scopes: String(
      process.env.ZOHO_SCOPES ||
        "ZohoMail.accounts.READ,ZohoMail.folders.READ,ZohoMail.messages.READ",
    ).trim(),
  };
  if (!values.clientId || !values.clientSecret || !values.redirectUri) {
    throw new Error("Zoho OAuth environment variables are not configured.");
  }
  return values;
}

exports.connectZoho = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?._id;
    if (!userId)
      return res
        .status(401)
        .json({ success: false, message: "User authentication required." });

    const config = requiredConfig();
    const state = jwt.sign(
      { userId: userId.toString(), provider: "zoho" },
      process.env.JWT_SECRET,
      {
        expiresIn: "10m",
      },
    );
    const query = new URLSearchParams({
      scope: config.scopes,
      client_id: config.clientId,
      response_type: "code",
      access_type: "offline",
      prompt: "consent",
      redirect_uri: config.redirectUri,
      state,
    });

    return res.status(200).json({
      success: true,
      message: "Zoho authorization URL generated.",
      authUrl: `${accountsBaseUrl()}/oauth/v2/auth?${query.toString()}`,
    });
  } catch (error) {
    console.error("Zoho Connect Error:", error.message);
    return res.status(500).json({ success: false, message: error.message });
  }
};

exports.zohoCallback = async (req, res) => {
  const redirectFailure = (error) =>
    res.redirect(
      302,
      `${APP_DEEP_LINK}?provider=zoho&success=false&error=${encodeURIComponent(error)}`,
    );

  try {
    const { code, state, error } = req.query;
    if (error) return redirectFailure("cancelled");
    if (!code) return redirectFailure("no_code");
    if (!state) return redirectFailure("no_state");

    let decoded;
    try {
      decoded = jwt.verify(state, process.env.JWT_SECRET);
    } catch (_) {
      return redirectFailure("invalid_state");
    }
    if (!decoded.userId || decoded.provider !== "zoho")
      return redirectFailure("invalid_state");

    const config = requiredConfig();
    const tokenBody = new URLSearchParams({
      grant_type: "authorization_code",
      client_id: config.clientId,
      client_secret: config.clientSecret,
      redirect_uri: config.redirectUri,
      code: String(code),
    });
    const tokenResponse = await axios.post(
      `${accountsBaseUrl()}/oauth/v2/token`,
      tokenBody,
      {
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
      },
    );
    const tokens = tokenResponse.data || {};
    if (!tokens.access_token)
      return redirectFailure(tokens.error || "no_access_token");

    const existing = await ZOHO_INTEGRATION.findOne({ userId: decoded.userId });
    const refreshToken = tokens.refresh_token || existing?.refreshToken;
    if (!refreshToken) return redirectFailure("no_refresh_token");

    const temporary = {
      accessToken: tokens.access_token,
      refreshToken,
      expiresAt: new Date(
        Date.now() + Number(tokens.expires_in || 3600) * 1000,
      ),
      save: async () => {},
    };
    const accountsPayload = await zohoGet(temporary, "/api/accounts");
    const accounts = Array.isArray(accountsPayload?.data)
      ? accountsPayload.data
      : [];
    const account =
      accounts.find((item) => item.primaryEmailAddress) || accounts[0];
    const accountId = account?.accountId;
    const email = account?.primaryEmailAddress || account?.emailAddress;
    if (!accountId || !email) return redirectFailure("no_email");

    await ZOHO_INTEGRATION.findOneAndUpdate(
      { userId: decoded.userId },
      {
        $set: {
          userId: decoded.userId,
          email: String(email).toLowerCase(),
          accountId: String(accountId),
          accessToken: tokens.access_token,
          refreshToken,
          apiDomain: tokens.api_domain || null,
          scope: config.scopes,
          tokenType: tokens.token_type || "Bearer",
          expiresAt: new Date(
            Date.now() + Number(tokens.expires_in || 3600) * 1000,
          ),
          connectedAt: new Date(),
          lastSyncAt: new Date(),
          lastSyncError: null,
        },
      },
      { upsert: true, returnDocument: "after" },
    );

    return res.redirect(
      302,
      `${APP_DEEP_LINK}?provider=zoho&success=true&email=${encodeURIComponent(email)}`,
    );
  } catch (error) {
    console.error("Zoho Callback Error:", {
      step: error.zohoPath ? "mail_account_lookup" : "oauth_token_exchange",
      endpoint: error.zohoPath || `${accountsBaseUrl()}/oauth/v2/token`,
      statusCode: error.statusCode || error.response?.status,
      response: error.zohoResponse || error.response?.data,
      message: error.message,
    });

    if (
      error.zohoPath === "/api/accounts" &&
      (error.statusCode === 500 || error.zohoResponse?.status?.code === 500)
    ) {
      return redirectFailure("zoho_mail_account_unavailable");
    }

    return redirectFailure(
      error.response?.data?.error || error.message || "callback_failed",
    );
  }
};

exports.getZohoStatus = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?._id;
    if (!userId)
      return res
        .status(401)
        .json({ success: false, message: "User authentication required." });
    const integration = await ZOHO_INTEGRATION.findOne({ userId }).select(
      "email connectedAt lastSyncAt lastSyncError",
    );
    if (!integration) {
      return res
        .status(200)
        .json({
          success: true,
          connected: false,
          message: "Zoho Mail is not connected.",
        });
    }
    return res.status(200).json({
      success: true,
      connected: true,
      email: integration.email,
      connectedAt: integration.connectedAt,
      lastSyncAt: integration.lastSyncAt,
      syncHealthy: !integration.lastSyncError,
    });
  } catch (error) {
    console.error("Zoho Status Error:", error.message);
    return res
      .status(500)
      .json({ success: false, message: "Failed to get Zoho Mail status." });
  }
};

exports.disconnectZoho = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?._id;
    if (!userId)
      return res
        .status(401)
        .json({ success: false, message: "User authentication required." });
    const integration = await ZOHO_INTEGRATION.findOne({ userId });
    if (!integration)
      return res
        .status(404)
        .json({ success: false, message: "Zoho Mail is not connected." });

    try {
      await axios.post(`${accountsBaseUrl()}/oauth/v2/token/revoke`, null, {
        params: { token: integration.refreshToken },
      });
    } catch (error) {
      console.warn(
        "Zoho token revoke failed:",
        error.response?.data || error.message,
      );
    }
    await ZOHO_INTEGRATION.deleteOne({ userId });
    return res
      .status(200)
      .json({
        success: true,
        connected: false,
        message: "Zoho Mail disconnected successfully.",
      });
  } catch (error) {
    console.error("Zoho Disconnect Error:", error.message);
    return res
      .status(500)
      .json({ success: false, message: "Failed to disconnect Zoho Mail." });
  }
};

exports.syncZoho = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const integration = await ZOHO_INTEGRATION.findOne({ userId });
    if (!integration)
      return res
        .status(404)
        .json({ success: false, message: "Zoho Mail is not connected." });
    const result = await syncZohoReplies(integration);
    return res
      .status(200)
      .json({
        success: true,
        message: "Zoho replies synchronized.",
        ...result,
      });
  } catch (error) {
    console.error(
      "Zoho Manual Sync Error:",
      error.response?.data || error.message,
    );
    return res
      .status(500)
      .json({ success: false, message: "Unable to synchronize Zoho replies." });
  }
};
