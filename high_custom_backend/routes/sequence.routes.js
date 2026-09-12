const express = require("express");

const router = express.Router();

const sequencrCtrl = require("../controller/sequence.controller");

const authMiddleware = require("../middleware/auth.middleware");
const {
  requireAppRight,
  requireAccessRight,
} = require("../middleware/user-access");

const sequenceUpload = require("../middleware/sequenceUpload.middleware");

// CREATE SEQUENCE

router.post(
  "/create-sequence",
  authMiddleware,
  requireAppRight("sequences"),
  requireAccessRight("createSequence"),
  sequenceUpload,
  sequencrCtrl.createSequence,
);

router.put(
  "/:sequenceId",
  authMiddleware,
  requireAppRight("sequences"),
  requireAccessRight("editSequence"),
  sequenceUpload,
  sequencrCtrl.updateSequence,
);

// GET TRACKING SUMMARY

router.get(
  "/tracking-summary",
  authMiddleware,
  requireAppRight("trackingReport"),
  requireAccessRight("viewTrackingReport"),
  sequencrCtrl.getTrackingSummary,
);

// GET SEQUENCES

router.get(
  "/",
  authMiddleware,
  requireAppRight("sequences"),
  requireAccessRight("viewSequences"),
  sequencrCtrl.getSequence,
);

// MANUALLY RUN SEQUENCE

router.post(
  "/run",
  authMiddleware,
  requireAppRight("sequences"),
  requireAccessRight("runSequence"),
  sequencrCtrl.runSequence,
);

router.delete(
  "/:sequenceId",
  authMiddleware,
  requireAccessRight("deleteSequence"),
  sequencrCtrl.deleteSequence,
);

module.exports = router;
