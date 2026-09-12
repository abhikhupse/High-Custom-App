const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/auth.middleware");
const businessCardCtrl = require("../controller/businessCard.controller");
const {
  requireAppRight,
  requireAccessRight,
} = require("../middleware/user-access");

router.post(
  "/create-BusinessCard",
  authMiddleware,
  requireAppRight("businessLink"),
  requireAccessRight("createBusinessLink"),
  businessCardCtrl.createBusinessCard,
);
router.put(
  "/update-businessCard",
  authMiddleware,
  requireAppRight("businessLink"),
  requireAccessRight("editBusinessLink"),
  businessCardCtrl.updateBusinessCard,
);
router.delete(
  "/delete-businessCard",
  authMiddleware,
  requireAppRight("businessLink"),
  requireAccessRight("deleteBusinessLink"),
  businessCardCtrl.deleteBusinessCard,
);
router.get(
  "/fetch-businessCard",
  authMiddleware,
  requireAppRight("businessLink"),
  requireAccessRight("viewBusinessLink"),
  businessCardCtrl.fetchBusinessCard,
);
module.exports = router;
