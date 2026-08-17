const express = require("express");

const router = express.Router();

const authMiddleware = require("../middleware/auth.middleware");

const gmailCtrl = require("../controller/gmail_integration.controller");

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

// ============================================================
// GMAIL DISCONNECT
// ============================================================

router.delete("/gmail/disconnect", authMiddleware, gmailCtrl.disconnectGmail);

module.exports = router;
