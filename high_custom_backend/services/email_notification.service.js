const EMAIL_NOTIFICATION = require("../model/email_notification.model");
const { sendEmailEventPush } = require("./push_notification.service");

async function recordEmailNotification({
  userId,
  deliveryId,
  type,
  email,
  occurredAt,
}) {
  if (!userId || !deliveryId || !type || !email) return null;

  try {
    const result = await EMAIL_NOTIFICATION.updateOne(
      { deliveryId, type },
      {
        $setOnInsert: {
          userId,
          deliveryId,
          type,
          email: String(email).trim().toLowerCase(),
          occurredAt: occurredAt || new Date(),
        },
      },
      { upsert: true, setDefaultsOnInsert: true },
    );
    if (!result.upsertedCount) return null;

    const notification = await EMAIL_NOTIFICATION.findById(result.upsertedId).lean();
    if (notification) {
      sendEmailEventPush({
        userId,
        notificationId: notification._id,
        email: notification.email,
        type,
      }).catch((error) => console.error("Email push send failed:", error.message));
    }
    return notification;
  } catch (error) {
    // Notification failure must never interrupt delivery, tracking, or reply
    // processing. A duplicate-key error only means the event was already seen.
    if (error?.code !== 11000) {
      console.error("Email notification record failed:", error.message);
    }
    return null;
  }
}

module.exports = { recordEmailNotification };
