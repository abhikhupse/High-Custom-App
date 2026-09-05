const nodemailer = require("nodemailer");
const axios = require("axios");
const GMAIL = require("../model/gmail_integration.model");
const { createMimeMessage } = require("../utils/emailMessage");

function createRegistrationTransport() {
  const mode = process.env.OTP_EMAIL_TRANSPORT || (process.env.RENDER ? "gmail_api" : "smtp");
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
      const token = await axios.post("https://oauth2.googleapis.com/token", new URLSearchParams({
        client_id: process.env.GOOGLE_CLIENT_ID || "",
        client_secret: process.env.GOOGLE_CLIENT_SECRET || "",
        refresh_token: integration.refreshToken,
        grant_type: "refresh_token",
      }), requestOptions);
      if (!token.data?.access_token) throw new Error("Gmail did not return an access token");
      const raw = await createMimeMessage({ ...options, from: sender });
      const result = await axios.post("https://gmail.googleapis.com/gmail/v1/users/me/messages/send", { raw }, {
        ...requestOptions, headers: { Authorization: `Bearer ${token.data.access_token}` },
      });
      if (!result.data?.id) throw new Error("Gmail did not confirm OTP acceptance");
      return { messageId: result.data.id };
    },
  };
}

module.exports = { createRegistrationTransport };
