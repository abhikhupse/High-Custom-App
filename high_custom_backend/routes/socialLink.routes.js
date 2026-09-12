const express = require("express");
const auth = require("../middleware/auth.middleware");
const controller = require("../controller/socialLink.controller");
const {
  requireAppRight,
  requireAccessRight,
} = require("../middleware/user-access");

const router = express.Router();

router.get("/r/:id", controller.redirect);
router.get("/all-links/:userId", controller.allLinksPage);
router.get(
  "/",
  auth,
  requireAppRight("socialLinks"),
  requireAccessRight("viewSocialLinks"),
  controller.list,
);
router.post(
  "/",
  auth,
  requireAppRight("socialLinks"),
  requireAccessRight("createSocialLink"),
  controller.create,
);
router.patch(
  "/:id",
  auth,
  requireAppRight("socialLinks"),
  requireAccessRight("editSocialLink"),
  controller.update,
);
router.delete(
  "/:id",
  auth,
  requireAppRight("socialLinks"),
  requireAccessRight("deleteSocialLink"),
  controller.remove,
);
router.post(
  "/generate-qr",
  auth,
  requireAppRight("socialLinks"),
  requireAccessRight("createSocialLink"),
  controller.generateQr,
);
router.get(
  "/qr",
  auth,
  requireAppRight("socialLinks"),
  requireAccessRight("viewSocialLinks"),
  controller.listQr,
);
router.delete(
  "/:id/qr",
  auth,
  requireAppRight("socialLinks"),
  requireAccessRight("deleteSocialLink"),
  controller.deleteQr,
);

module.exports = router;
