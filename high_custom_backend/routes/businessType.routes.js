const express = require("express");
const authMiddleware = require("../middleware/auth.middleware");
const businessTypeController = require("../controller/businessType.controller");
const {
  requireAppRight,
  requireAccessRight,
} = require("../middleware/user-access");

const router = express.Router();

router.get(
  "/",
  authMiddleware,
  requireAppRight("businessLink"),
  requireAccessRight("viewBusinessLink"),
  businessTypeController.listBusinessTypes,
);
router.post(
  "/",
  authMiddleware,
  requireAppRight("businessLink"),
  requireAccessRight("createBusinessLink"),
  businessTypeController.createBusinessType,
);
router.patch(
  "/:id",
  authMiddleware,
  requireAppRight("businessLink"),
  requireAccessRight("editBusinessLink"),
  businessTypeController.updateBusinessType,
);
router.delete(
  "/:id",
  authMiddleware,
  requireAppRight("businessLink"),
  requireAccessRight("deleteBusinessLink"),
  businessTypeController.deleteBusinessType,
);

module.exports = router;
