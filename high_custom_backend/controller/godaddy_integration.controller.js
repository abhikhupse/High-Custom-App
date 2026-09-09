const GODADDY_INTEGRATION = require("../model/godaddy_integration.model");
const { encryptCredential } = require("../utils/credentialCipher");
const {
  createGoDaddyTransport,
} = require("../services/godaddy_email.service");

function userIdFrom(req) {
  return req.user?.id || req.user?._id;
}

function validEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(value || "").trim());
}

exports.connectGoDaddy = async (req, res) => {
  try {
    const userId = userIdFrom(req);
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required.",
      });
    }

    const email = String(req.body?.email || "").trim().toLowerCase();
    const password = String(req.body?.password || "");
    const senderName = String(req.body?.senderName || "").trim().slice(0, 120);

    if (!validEmail(email)) {
      return res.status(422).json({
        success: false,
        message: "Enter a valid GoDaddy email address.",
      });
    }
    if (!password) {
      return res.status(422).json({
        success: false,
        message: "GoDaddy mailbox password is required.",
      });
    }

    try {
      await createGoDaddyTransport(email, password).verify();
    } catch (error) {
      console.error("GoDaddy SMTP verification failed:", {
        userId: String(userId),
        email,
        code: error?.code,
        responseCode: error?.responseCode,
      });
      return res.status(400).json({
        success: false,
        message:
          error?.code === "EAUTH"
            ? "GoDaddy rejected the email or password. Check the mailbox credentials."
            : "Unable to connect to GoDaddy SMTP. Please try again.",
      });
    }

    const encrypted = encryptCredential(password);
    const integration = await GODADDY_INTEGRATION.findOneAndUpdate(
      { userId },
      {
        $set: {
          userId,
          email,
          senderName,
          ...encrypted,
          connectedAt: new Date(),
          lastVerifiedAt: new Date(),
          lastError: null,
        },
      },
      { upsert: true, returnDocument: "after", runValidators: true },
    );

    return res.status(200).json({
      success: true,
      connected: true,
      email: integration.email,
      senderName: integration.senderName,
      connectedAt: integration.connectedAt,
      message: "GoDaddy Email connected successfully.",
    });
  } catch (error) {
    console.error("GoDaddy Connect Error:", error.message);
    return res.status(500).json({
      success: false,
      message:
        error.message.includes("GODADDY_CREDENTIAL_KEY")
          ? error.message
          : "Failed to connect GoDaddy Email.",
    });
  }
};

exports.getGoDaddyStatus = async (req, res) => {
  try {
    const userId = userIdFrom(req);
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required.",
      });
    }
    const integration = await GODADDY_INTEGRATION.findOne({ userId }).select(
      "email senderName connectedAt lastVerifiedAt",
    );
    return res.status(200).json({
      success: true,
      connected: Boolean(integration),
      email: integration?.email || null,
      senderName: integration?.senderName || null,
      connectedAt: integration?.connectedAt || null,
      lastVerifiedAt: integration?.lastVerifiedAt || null,
    });
  } catch (error) {
    console.error("GoDaddy Status Error:", error.message);
    return res.status(500).json({
      success: false,
      message: "Failed to get GoDaddy Email status.",
    });
  }
};

exports.disconnectGoDaddy = async (req, res) => {
  try {
    const userId = userIdFrom(req);
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required.",
      });
    }
    await GODADDY_INTEGRATION.deleteOne({ userId });
    return res.status(200).json({
      success: true,
      connected: false,
      message: "GoDaddy Email disconnected successfully.",
    });
  } catch (error) {
    console.error("GoDaddy Disconnect Error:", error.message);
    return res.status(500).json({
      success: false,
      message: "Failed to disconnect GoDaddy Email.",
    });
  }
};
