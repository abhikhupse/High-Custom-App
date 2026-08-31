const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/auth.middleware");
const businessCardCtrl = require("../controller/businessCard.controller");

router.post(
  "/create-BusinessCard",
  authMiddleware,
  businessCardCtrl.createBusinessCard,
);
router.put(
  "/update-businessCard",
  authMiddleware,
  businessCardCtrl.updateBusinessCard,
);
router.delete(
  "/delete-businessCard",
  authMiddleware,
  businessCardCtrl.deleteBusinessCard,
);
router.get(
  "/fetch-businessCard",
  authMiddleware,
  businessCardCtrl.fetchBusinessCard,
);
module.exports = router;
