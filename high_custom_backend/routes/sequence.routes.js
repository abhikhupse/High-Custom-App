const express = require("express");

const router = express.Router();

const sequencrCtrl = require("../controller/sequence.controller");

const authMiddleware = require("../middleware/auth.middleware");

const sequenceUpload = require("../middleware/sequenceUpload.middleware");

// ============================================================
// CREATE SEQUENCE
// ============================================================

router.post(
  "/create-sequence",
  authMiddleware,
  sequenceUpload,
  sequencrCtrl.createSequence,
);

router.put(
  "/:sequenceId",
  authMiddleware,
  sequenceUpload,
  sequencrCtrl.updateSequence,
);

// ============================================================
// GET TRACKING SUMMARY
// ============================================================

router.get(
  "/tracking-summary",
  authMiddleware,
  sequencrCtrl.getTrackingSummary,
);

// ============================================================
// GET SEQUENCES
// ============================================================

router.get("/", authMiddleware, sequencrCtrl.getSequence);

// ============================================================
// MANUALLY RUN SEQUENCE
// ============================================================

router.post("/run", authMiddleware, sequencrCtrl.runSequence);

module.exports = router;
