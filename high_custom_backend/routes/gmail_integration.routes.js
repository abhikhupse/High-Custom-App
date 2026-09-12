const express = require("express");

const router = express.Router();

const authMiddleware = require("../middleware/auth.middleware");

const gmailCtrl = require("../controller/gmail_integration.controller");
const zohoCtrl = require("../controller/zoho_integration.controller");
const goDaddyCtrl = require("../controller/godaddy_integration.controller");
const {
  requireAppRight,
  requireAccessRight,
} = require("../middleware/user-access");

// ============================================================
// GMAIL CONNECT
// ============================================================

router.get(
  "/gmail/connect",
  authMiddleware,
  requireAppRight("integrations"),
  requireAccessRight("connectIntegration"),
  gmailCtrl.connectGmail,
);

// ============================================================
// GOOGLE OAUTH CALLBACK
// IMPORTANT: NO AUTH MIDDLEWARE
// ============================================================

router.get("/gmail/callback", gmailCtrl.gmailCallback);

// ============================================================
// GMAIL STATUS
// ============================================================

router.get(
  "/gmail/status",
  authMiddleware,
  requireAppRight("integrations"),
  requireAccessRight("viewIntegrations"),
  gmailCtrl.getGmailStatus,
);

router.post(
  "/gmail/reply-watch",
  authMiddleware,
  requireAppRight("integrations"),
  requireAccessRight("connectIntegration"),
  gmailCtrl.registerReplyWatch,
);

// Google Cloud Pub/Sub calls this route. It uses a verification token and/or
// an OIDC identity token instead of the application's JWT middleware.
router.post("/gmail/notifications", gmailCtrl.receiveGmailNotification);

// ============================================================
// GMAIL DISCONNECT
// ============================================================

router.delete(
  "/gmail/disconnect",
  authMiddleware,
  requireAppRight("integrations"),
  requireAccessRight("disconnectIntegration"),
  gmailCtrl.disconnectGmail,
);

router.get(
  "/zoho/connect",
  authMiddleware,
  requireAppRight("integrations"),
  requireAccessRight("connectIntegration"),
  zohoCtrl.connectZoho,
);
router.get("/zoho/callback", zohoCtrl.zohoCallback);
router.get(
  "/zoho/status",
  authMiddleware,
  requireAppRight("integrations"),
  requireAccessRight("viewIntegrations"),
  zohoCtrl.getZohoStatus,
);
router.post(
  "/zoho/sync",
  authMiddleware,
  requireAppRight("integrations"),
  requireAccessRight("connectIntegration"),
  zohoCtrl.syncZoho,
);
router.delete(
  "/zoho/disconnect",
  authMiddleware,
  requireAppRight("integrations"),
  requireAccessRight("disconnectIntegration"),
  zohoCtrl.disconnectZoho,
);

router.post(
  "/godaddy/connect",
  authMiddleware,
  requireAppRight("integrations"),
  requireAccessRight("connectIntegration"),
  goDaddyCtrl.connectGoDaddy,
);
router.get(
  "/godaddy/status",
  authMiddleware,
  requireAppRight("integrations"),
  requireAccessRight("viewIntegrations"),
  goDaddyCtrl.getGoDaddyStatus,
);
router.delete(
  "/godaddy/disconnect",
  authMiddleware,
  requireAppRight("integrations"),
  requireAccessRight("disconnectIntegration"),
  goDaddyCtrl.disconnectGoDaddy,
);

module.exports = router;
