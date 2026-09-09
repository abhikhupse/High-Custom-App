const EMAIL_NOTIFICATION = require("../model/email_notification.model");

async function recordEmailNotification({
  userId,
  deliveryId,
  type,
  email,
  occurredAt,
}) {
  if (!userId || !deliveryId || !type || !email) return null;

  try {
    return await EMAIL_NOTIFICATION.findOneAndUpdate(
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
      { upsert: true, returnDocument: "after", setDefaultsOnInsert: true },
    );
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
