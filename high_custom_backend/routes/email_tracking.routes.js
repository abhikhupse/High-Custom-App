const express = require("express");

const router = express.Router();

const emailTrackingController = require("../controller/email_tracking.controller");

// ============================================================
// EMAIL OPEN TRACKING
// ============================================================

// This route is called automatically by
// the tracking pixel inside the email.
//
// DO NOT protect this route with JWT.

router.get("/open/:trackingId", emailTrackingController.trackOpen);

// ============================================================
// TRACKING REPORT
// ============================================================

// Flutter calls this endpoint.
//
// JWT is required.

router.get(
  "/report",
  require("../middleware/auth.middleware"),
  emailTrackingController.getTrackingReport,
);

module.exports = router;
