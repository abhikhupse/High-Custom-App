const express = require("express");

const authMiddleware = require("../middleware/auth.middleware");
const controller = require("../controller/email_notification.controller");

const router = express.Router();

router.get("/", authMiddleware, controller.getNotifications);
router.patch("/read", authMiddleware, controller.markAllRead);

module.exports = router;
