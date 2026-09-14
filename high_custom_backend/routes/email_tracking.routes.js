const express = require("express");

const router = express.Router();

const emailTrackingController = require("../controller/email_tracking.controller");
const { requireAppRight, requireAccessRight } = require("../middleware/user-access");

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
  requireAppRight("trackingReport"),
  requireAccessRight("viewTrackingReport"),
  emailTrackingController.getTrackingReport,
);

router.get(
  "/interest-details",
  require("../middleware/auth.middleware"),
  requireAppRight("interestedLeads"),
  requireAccessRight("viewInterestedLeads"),
  emailTrackingController.getInterestDetails,
);

module.exports = router;
