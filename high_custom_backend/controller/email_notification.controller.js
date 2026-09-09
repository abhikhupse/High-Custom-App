const EMAIL_NOTIFICATION = require("../model/email_notification.model");

exports.getNotifications = async (req, res) => {
  try {
    const limit = Math.min(Math.max(Number(req.query.limit) || 50, 1), 100);
    const notifications = await EMAIL_NOTIFICATION.find({ userId: req.user.id })
      .sort({ occurredAt: -1 })
      .limit(limit)
      .lean();
    const unreadCount = await EMAIL_NOTIFICATION.countDocuments({
      userId: req.user.id,
      readAt: null,
    });

    return res.status(200).json({
      success: true,
      unreadCount,
      notifications,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Unable to load notifications.",
    });
  }
};

exports.markAllRead = async (req, res) => {
  try {
    await EMAIL_NOTIFICATION.updateMany(
      { userId: req.user.id, readAt: null },
      { $set: { readAt: new Date() } },
    );
    return res.status(200).json({ success: true });
  } catch (_) {
    return res.status(500).json({
      success: false,
      message: "Unable to mark notifications as read.",
    });
  }
};
