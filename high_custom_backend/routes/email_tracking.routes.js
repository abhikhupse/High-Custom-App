const express = require("express");
const router = express.Router();

const trackingCtrl = require("../controller/email_tracking.controller");

router.get("/open/:trackingId", trackingCtrl.trackEmailOpen);

module.exports = router;
