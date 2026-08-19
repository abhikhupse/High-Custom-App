const express = require("express");

const router = express.Router();

const User = require("./user.routes");

const Sequence = require("./sequence.routes");

const Leads = require("./leads.router");

const Integration = require("./gmail_integration.routes");

const emailTrackingRoutes = require("./email_tracking.routes");

// ============================================================
// USER
// ============================================================

router.use("/user", User);

// ============================================================
// SEQUENCE
// ============================================================

router.use("/sequence", Sequence);

// ============================================================
// LEADS
// ============================================================

router.use("/leads", Leads);

// ============================================================
// INTEGRATIONS
// ============================================================

router.use("/integrations", Integration);

// ============================================================
// EMAIL TRACKING
// ============================================================

router.use("/email-tracking", emailTrackingRoutes);

module.exports = router;
