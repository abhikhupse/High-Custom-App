const express = require("express");
const auth = require("../middleware/auth.middleware");
const controller = require("../controller/businessLinkSettings.controller");
const router = express.Router();
const {
  requireAppRight,
  requireAccessRight,
} = require("../middleware/user-access");
router.get(
  "/",
  auth,
  requireAppRight("businessLink"),
  requireAccessRight("viewBusinessLink"),
  controller.get,
);
router.put(
  "/",
  auth,
  requireAppRight("businessLink"),
  requireAccessRight("editBusinessLink"),
  controller.save,
);
module.exports = router;
