const { google } = require("googleapis");
const jwt = require("jsonwebtoken");

const GMAIL_INTEGRATION = require("../model/gmail_integration.model");

const createGoogleOAuthClient = require("../config/google_oauth");
const {
  registerGmailWatch,
  recordPendingGmailNotification,
  processGmailNotification,
} = require("../services/gmail_reply.service");

// ============================================================
// DEEP LINK
// ============================================================

const APP_DEEP_LINK = "highcustom://integration";

// ============================================================
// CONNECT GMAIL
// ============================================================

exports.connectGmail = async (req, res) => {
  try {
    // ========================================================
    // GET LOGGED-IN USER
    // ========================================================

    const userId = req.user?.id || req.user?._id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required.",
      });
    }

    console.log("================================================");
    console.log("STARTING GMAIL CONNECTION");
    console.log("User ID:", userId);
    console.log("================================================");

    // ========================================================
    // CREATE OAUTH STATE
    // ========================================================

    const state = jwt.sign(
      {
        userId: userId.toString(),
      },
      process.env.JWT_SECRET,
      // {
      //   expiresIn: "10m",
      // },
    );

    // ========================================================
    // CREATE GOOGLE OAUTH CLIENT
    // ========================================================

    const oauth2Client = createGoogleOAuthClient();

    console.log("====================================");
    console.log("GOOGLE CLIENT ID:", process.env.GOOGLE_CLIENT_ID);
    console.log("GOOGLE REDIRECT URI:", process.env.GOOGLE_REDIRECT_URI);
    console.log("====================================");

    // ========================================================
    // GOOGLE AUTH URL
    // ========================================================

    const authUrl = oauth2Client.generateAuthUrl({
      access_type: "offline",

      prompt: "consent",

      scope: [
        "openid",
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/gmail.send",
        "https://www.googleapis.com/auth/gmail.modify",
      ],

      state: state,
    });

    console.log("Google OAuth URL generated.");

    // ========================================================
    // RESPONSE
    // ========================================================

    return res.status(200).json({
      success: true,
      message: "Gmail authorization URL generated.",
      authUrl: authUrl,
    });
  } catch (error) {
    console.error("Gmail Connect Error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to connect Gmail.",
      error: error.message,
    });
  }
};

// ============================================================
// GMAIL CALLBACK
// ============================================================

exports.gmailCallback = async (req, res) => {
  try {
    const { code, state, error } = req.query;

    console.log("");
    console.log("================================================");
    console.log("GMAIL OAUTH CALLBACK");
    console.log("================================================");
    console.log("Code received:", !!code);
    console.log("State received:", !!state);
    console.log("Google error:", error);
    console.log("================================================");

    // ========================================================
    // GOOGLE AUTHORIZATION ERROR
    // ========================================================

    if (error) {
      console.error("Google OAuth Error:", error);

      return res.redirect(`${APP_DEEP_LINK}?success=false&error=cancelled`);
    }

    // ========================================================
    // CHECK CODE
    // ========================================================

    if (!code) {
      console.error("Authorization code missing.");

      return res.redirect(`${APP_DEEP_LINK}?success=false&error=no_code`);
    }

    // ========================================================
    // CHECK STATE
    // ========================================================

    if (!state) {
      console.error("OAuth state missing.");

      return res.redirect(`${APP_DEEP_LINK}?success=false&error=no_state`);
    }

    // ========================================================
    // VERIFY STATE
    // ========================================================

    let decodedState;

    try {
      decodedState = jwt.verify(state, process.env.JWT_SECRET);
    } catch (verifyError) {
      console.error("OAuth State Verification Error:", verifyError.message);

      return res.redirect(`${APP_DEEP_LINK}?success=false&error=invalid_state`);
    }

    // ========================================================
    // GET USER ID
    // ========================================================

    const userId = decodedState.userId;

    if (!userId) {
      console.error("User ID not found in OAuth state.");

      return res.redirect(`${APP_DEEP_LINK}?success=false&error=no_user`);
    }

    console.log("OAuth User ID:", userId);

    // ========================================================
    // CREATE GOOGLE CLIENT
    // ========================================================

    const oauth2Client = createGoogleOAuthClient();

    // ========================================================
    // EXCHANGE CODE FOR TOKENS
    // ========================================================

    const { tokens } = await oauth2Client.getToken(code);

    console.log("Google tokens received.");

    // ========================================================
    // CHECK ACCESS TOKEN
    // ========================================================

    if (!tokens.access_token) {
      console.error("Google did not return access token.");

      return res.redirect(
        `${APP_DEEP_LINK}?success=false&error=no_access_token`,
      );
    }

    // ========================================================
    // SET CREDENTIALS
    // ========================================================

    oauth2Client.setCredentials(tokens);

    // ========================================================
    // GET GOOGLE USER INFO
    // ========================================================

    const oauth2 = google.oauth2({
      auth: oauth2Client,
      version: "v2",
    });

    const { data } = await oauth2.userinfo.get();

    const gmailEmail = data.email;

    console.log("Gmail Email:", gmailEmail);

    // ========================================================
    // CHECK EMAIL
    // ========================================================

    if (!gmailEmail) {
      console.error("Unable to retrieve Gmail email.");

      return res.redirect(`${APP_DEEP_LINK}?success=false&error=no_email`);
    }

    // ========================================================
    // FIND EXISTING INTEGRATION
    // ========================================================

    const existingIntegration = await GMAIL_INTEGRATION.findOne({
      userId: userId,
    });

    // ========================================================
    // GET REFRESH TOKEN
    // ========================================================

    let refreshToken = tokens.refresh_token;

    if (!refreshToken && existingIntegration) {
      refreshToken = existingIntegration.refreshToken;

      console.log("Using existing refresh token.");
    }

    // ========================================================
    // REFRESH TOKEN REQUIRED
    // ========================================================

    if (!refreshToken) {
      console.error("Google did not provide refresh token.");

      return res.redirect(
        `${APP_DEEP_LINK}?success=false&error=no_refresh_token`,
      );
    }

    // ========================================================
    // SAVE GMAIL INTEGRATION
    // ========================================================

    const savedIntegration = await GMAIL_INTEGRATION.findOneAndUpdate(
      {
        userId: userId,
      },

      {
        userId: userId,

        email: gmailEmail,

        accessToken: tokens.access_token,

        refreshToken: refreshToken,

        scope: tokens.scope || "",

        tokenType: tokens.token_type || "Bearer",

        expiryDate: tokens.expiry_date || null,

        connectedAt: new Date(),

        ...(existingIntegration && existingIntegration.email !== gmailEmail
          ? {
              lastHistoryId: null,
              watchExpiration: null,
              watchLastRenewedAt: null,
              replySyncLastError: null,
            }
          : {}),
      },

      {
        returnDocument: "after",
        upsert: true,
      },
    );

    // Register reply notifications immediately after Gmail is connected. A
    // missing Pub/Sub configuration does not block the Gmail connection.
    try {
      const watch = await registerGmailWatch(savedIntegration);
      console.log("Gmail reply watch:", watch);
    } catch (watchError) {
      console.error("Gmail reply watch registration failed:", watchError.message);
    }

    console.log("");
    console.log("================================================");
    console.log("GMAIL CONNECTED SUCCESSFULLY");
    console.log("================================================");
    console.log("User ID:", userId);
    console.log("Gmail:", gmailEmail);
    console.log("MongoDB: SAVED");
    console.log("================================================");

    // ========================================================
    // REDIRECT BACK TO FLUTTER
    // ========================================================

    const appRedirectUrl =
      `${APP_DEEP_LINK}` +
      `?success=true` +
      `&email=${encodeURIComponent(gmailEmail)}`;

    console.log("Redirecting to Flutter:");

    console.log(appRedirectUrl);

    return res.redirect(302, appRedirectUrl);
  } catch (error) {
    console.error("");
    console.error("================================================");
    console.error("GMAIL CALLBACK ERROR");
    console.error("================================================");
    console.error(error);
    console.error("================================================");

    const errorMessage = error?.message || "unknown_error";

    return res.redirect(
      302,
      `${APP_DEEP_LINK}` +
        `?success=false` +
        `&error=${encodeURIComponent(errorMessage)}`,
    );
  }
};

// ============================================================
// GET GMAIL STATUS
// ============================================================

exports.getGmailStatus = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?._id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required.",
      });
    }

    const integration = await GMAIL_INTEGRATION.findOne({
      userId: userId,
    }).select("-accessToken -refreshToken");

    // ========================================================
    // NOT CONNECTED
    // ========================================================

    if (!integration) {
      return res.status(200).json({
        success: true,
        connected: false,
        message: "Gmail is not connected.",
      });
    }

    // ========================================================
    // CONNECTED
    // ========================================================

    return res.status(200).json({
      success: true,

      connected: true,

      email: integration.email,

      connectedAt: integration.connectedAt,
    });
  } catch (error) {
    console.error("Gmail Status Error:", error);

    return res.status(500).json({
      success: false,

      message: "Failed to get Gmail status.",

      error: error.message,
    });
  }
};

// ============================================================
// DISCONNECT GMAIL
// ============================================================

exports.disconnectGmail = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?._id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required.",
      });
    }

    const integration = await GMAIL_INTEGRATION.findOne({
      userId: userId,
    });

    if (!integration) {
      return res.status(404).json({
        success: false,
        message: "Gmail is not connected.",
      });
    }

    // ========================================================
    // GOOGLE OAUTH CLIENT
    // ========================================================

    const oauth2Client = createGoogleOAuthClient();

    // ========================================================
    // REVOKE TOKEN
    // ========================================================

    try {
      await oauth2Client.revokeToken(integration.refreshToken);

      console.log("Google Gmail access revoked.");
    } catch (revokeError) {
      console.warn("Google revoke failed:", revokeError.message);
    }

    // ========================================================
    // DELETE DATABASE RECORD
    // ========================================================

    await GMAIL_INTEGRATION.deleteOne({
      userId: userId,
    });

    console.log("Gmail integration deleted.");

    return res.status(200).json({
      success: true,
      connected: false,
      message: "Gmail disconnected successfully.",
    });
  } catch (error) {
    console.error("Gmail Disconnect Error:", error);

    return res.status(500).json({
      success: false,

      message: "Failed to disconnect Gmail.",

      error: error.message,
    });
  }
};

// ============================================================
// REGISTER / RENEW GMAIL REPLY WATCH
// ============================================================

exports.registerReplyWatch = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const integration = await GMAIL_INTEGRATION.findOne({ userId });

    if (!integration) {
      return res.status(404).json({
        success: false,
        message: "Gmail is not connected.",
      });
    }

    const result = await registerGmailWatch(integration);

    return res.status(result.enabled ? 200 : 503).json({
      success: result.enabled,
      message: result.enabled
        ? "Gmail reply notifications enabled."
        : result.reason,
      watchExpiration: result.expiration || null,
    });
  } catch (error) {
    console.error("Gmail reply watch error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to enable Gmail reply notifications.",
      error: error.message,
    });
  }
};

// ============================================================
// GOOGLE CLOUD PUB/SUB PUSH WEBHOOK
// ============================================================

async function verifyPubSubRequest(req) {
  const expectedSecret = String(
    process.env.GMAIL_PUBSUB_VERIFICATION_TOKEN || "",
  ).trim();
  const expectedAudience = String(
    process.env.GMAIL_PUBSUB_OIDC_AUDIENCE || "",
  ).trim();

  if (expectedSecret) {
    const receivedSecret = String(
      req.query.token || req.get("X-Pubsub-Verification-Token") || "",
    );

    if (receivedSecret !== expectedSecret) return false;
  }

  if (expectedAudience) {
    const authorization = String(req.get("Authorization") || "");
    const idToken = authorization.startsWith("Bearer ")
      ? authorization.substring(7).trim()
      : "";

    if (!idToken) return false;

    const verifier = createGoogleOAuthClient();
    await verifier.verifyIdToken({ idToken, audience: expectedAudience });
  }

  return Boolean(expectedSecret || expectedAudience);
}

exports.receiveGmailNotification = async (req, res) => {
  try {
    if (!(await verifyPubSubRequest(req))) {
      return res.status(401).json({
        success: false,
        message: "Invalid Pub/Sub notification authentication.",
      });
    }

    const expectedSubscription = String(
      process.env.GMAIL_PUBSUB_SUBSCRIPTION || "",
    ).trim();

    if (expectedSubscription && req.body?.subscription !== expectedSubscription) {
      return res.status(403).json({
        success: false,
        message: "Unexpected Pub/Sub subscription.",
      });
    }

    const encodedData = req.body?.message?.data;

    if (!encodedData) {
      return res.status(400).json({
        success: false,
        message: "Pub/Sub message data is required.",
      });
    }

    let notification;

    try {
      notification = JSON.parse(
        Buffer.from(String(encodedData), "base64url").toString("utf8"),
      );
    } catch (_) {
      return res.status(400).json({
        success: false,
        message: "Invalid Pub/Sub message data.",
      });
    }

    if (!notification.emailAddress || !notification.historyId) {
      return res.status(400).json({
        success: false,
        message: "Gmail notification is missing required fields.",
      });
    }

    const integrationFound = await recordPendingGmailNotification(notification);

    if (!integrationFound) {
      // Unknown Gmail accounts do not need Pub/Sub retries.
      return res.status(204).send();
    }

    // Acknowledge promptly. Pub/Sub retries any non-successful or timed-out
    // delivery; mailbox processing continues independently.
    res.status(204).send();

    setImmediate(() => {
      processGmailNotification(notification)
        .then((result) => {
          console.log("Gmail reply notification processed:", result);
        })
        .catch((error) => {
          console.error("Gmail reply notification failed:", error);
        });
    });

    return undefined;
  } catch (error) {
    console.error("Gmail Pub/Sub webhook error:", error);

    if (!res.headersSent) {
      return res.status(500).json({
        success: false,
        message: "Unable to process Gmail notification.",
      });
    }

    return undefined;
  }
};
