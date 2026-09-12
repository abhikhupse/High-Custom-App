const express = require("express");

const authMiddleware = require("../middleware/auth.middleware");
const controller = require("../controller/email_notification.controller");
const {
  requireAppRight,
  requireAccessRight,
} = require("../middleware/user-access");

const router = express.Router();

router.get(
  "/",
  authMiddleware,
  requireAppRight("notifications"),
  requireAccessRight("viewNotifications"),
  controller.getNotifications,
);
router.patch(
  "/read",
  authMiddleware,
  requireAppRight("notifications"),
  requireAccessRight("markNotificationRead"),
  controller.markAllRead,
);
router.delete(
  "/:id",
  authMiddleware,
  requireAppRight("notifications"),
  requireAccessRight("deleteNotification"),
  controller.deleteNotification,
);

module.exports = router;
