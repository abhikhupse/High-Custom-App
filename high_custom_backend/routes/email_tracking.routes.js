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

router.get(
  "/response/:trackingId/:response",
  emailTrackingController.trackResponse,
);

router.post(
  "/response/:trackingId/:response/confirm",
  express.urlencoded({ extended: false, limit: "2kb" }),
  emailTrackingController.confirmResponse,
);

router.post(
  "/response/:trackingId/interested",
  emailTrackingController.submitInterestDetails,
);

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

router.get(
  "/interest-details",
  require("../middleware/auth.middleware"),
  emailTrackingController.getInterestDetails,
);

module.exports = router;
