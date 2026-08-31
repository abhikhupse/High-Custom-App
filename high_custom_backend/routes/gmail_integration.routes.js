const express = require("express");

const router = express.Router();

const authMiddleware = require("../middleware/auth.middleware");

const gmailCtrl = require("../controller/gmail_integration.controller");
const zohoCtrl = require("../controller/zoho_integration.controller");

// ============================================================
// GMAIL CONNECT
// ============================================================

router.get("/gmail/connect", authMiddleware, gmailCtrl.connectGmail);

// ============================================================
// GOOGLE OAUTH CALLBACK
// IMPORTANT: NO AUTH MIDDLEWARE
// ============================================================

router.get("/gmail/callback", gmailCtrl.gmailCallback);

// ============================================================
// GMAIL STATUS
// ============================================================

router.get("/gmail/status", authMiddleware, gmailCtrl.getGmailStatus);

router.post(
  "/gmail/reply-watch",
  authMiddleware,
  gmailCtrl.registerReplyWatch,
);

// Google Cloud Pub/Sub calls this route. It uses a verification token and/or
// an OIDC identity token instead of the application's JWT middleware.
router.post("/gmail/notifications", gmailCtrl.receiveGmailNotification);

// ============================================================
// GMAIL DISCONNECT
// ============================================================

router.delete("/gmail/disconnect", authMiddleware, gmailCtrl.disconnectGmail);

router.get("/zoho/connect", authMiddleware, zohoCtrl.connectZoho);
router.get("/zoho/callback", zohoCtrl.zohoCallback);
router.get("/zoho/status", authMiddleware, zohoCtrl.getZohoStatus);
router.post("/zoho/sync", authMiddleware, zohoCtrl.syncZoho);
router.delete("/zoho/disconnect", authMiddleware, zohoCtrl.disconnectZoho);

module.exports = router;
