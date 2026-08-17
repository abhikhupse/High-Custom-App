const express = require("express");
const router = express.Router();
const sequencrCtrl = require("../controller/sequence.controller");
const authMiddleware = require("../middleware/auth.middleware");
const sequenceUpload = require("../middleware/sequenceUpload.middleware");
router.post(
  "/create-sequence",
  authMiddleware,
  sequenceUpload,
  sequencrCtrl.createSequence,
);

router.get("/", authMiddleware, sequencrCtrl.getSequence);

module.exports = router;
