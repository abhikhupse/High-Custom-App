const nodemailer = require("nodemailer");
const axios = require("axios");
const GMAIL = require("../model/gmail_integration.model");
const { createMimeMessage } = require("../utils/emailMessage");

function createRegistrationTransport() {
  const isHosted = process.env.RENDER === "true" ||
    Boolean(process.env.RENDER_EXTERNAL_URL) ||
    process.env.NODE_ENV === "production";
  const mode = process.env.OTP_EMAIL_TRANSPORT || (isHosted ? "gmail_api" : "smtp");
  if (mode === "smtp") return nodemailer.createTransport({
    service: "gmail", connectionTimeout: 5000, greetingTimeout: 5000, socketTimeout: 8000,
    auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS },
  });
  if (mode !== "gmail_api") throw new Error("Unsupported OTP_EMAIL_TRANSPORT");
  const controller = new AbortController();
  return {
    close: () => controller.abort(),
    async sendMail(options) {
      // Only the explicitly configured application sender may send registration OTPs.
      const sender = String(process.env.EMAIL_USER || "").trim().toLowerCase();
      if (!sender) throw Object.assign(new Error("OTP sender is not configured"), { code: "OTP_NOT_CONFIGURED" });
      const integration = await GMAIL.findOne({ email: sender }).sort({ connectedAt: -1 }).lean();
      if (!integration?.refreshToken) {
        throw Object.assign(new Error("Connect the configured OTP sender in Gmail Integrations"), { code: "OTP_GMAIL_RECONNECT" });
      }
      const requestOptions = { timeout: 8000, signal: controller.signal };
      const clientId = String(process.env.GOOGLE_CLIENT_ID || "").trim();
      const clientSecret = String(process.env.GOOGLE_CLIENT_SECRET || "").trim();
      if (!clientId || !clientSecret) {
        throw Object.assign(new Error("Google OAuth credentials are missing"), { code: "OTP_GOOGLE_NOT_CONFIGURED" });
      }
      let token;
      try {
        token = await axios.post("https://oauth2.googleapis.com/token", new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        refresh_token: integration.refreshToken,
        grant_type: "refresh_token",
      }), requestOptions);
      } catch (error) {
        const googleCode = error.response?.data?.error;
        if (googleCode === "invalid_grant") error.code = "OTP_GMAIL_RECONNECT";
        else if (googleCode === "invalid_client") error.code = "OTP_GOOGLE_CLIENT_INVALID";
        throw error;
      }
      if (!token.data?.access_token) throw new Error("Gmail did not return an access token");
      const raw = await createMimeMessage({ ...options, from: sender });
      let result;
      try {
        result = await axios.post("https://gmail.googleapis.com/gmail/v1/users/me/messages/send", { raw }, {
          ...requestOptions, headers: { Authorization: `Bearer ${token.data.access_token}` },
        });
      } catch (error) {
        const status = Number(error.response?.status || 0);
        if (status === 401) error.code = "OTP_GMAIL_RECONNECT";
        else if (status === 403) error.code = "OTP_GMAIL_PERMISSION";
        else if (status === 429) error.code = "OTP_GMAIL_QUOTA";
        throw error;
      }
      if (!result.data?.id) throw new Error("Gmail did not confirm OTP acceptance");
      return { messageId: result.data.id };
    },
  };
}

module.exports = { createRegistrationTransport };
