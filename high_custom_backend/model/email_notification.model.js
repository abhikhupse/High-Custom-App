const mongoose = require("mongoose");

const emailNotificationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    deliveryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "SequenceDelivery",
      required: true,
    },
    type: {
      type: String,
      enum: ["opened", "replied", "interested", "unsubscribed"],
      required: true,
    },
    email: { type: String, required: true, trim: true, lowercase: true },
    occurredAt: { type: Date, required: true, default: Date.now },
    readAt: { type: Date, default: null },
  },
  { timestamps: true },
);

// One notification per tracked action on each sent delivery.
emailNotificationSchema.index({ deliveryId: 1, type: 1 }, { unique: true });
emailNotificationSchema.index({ userId: 1, readAt: 1, occurredAt: -1 });

module.exports = mongoose.model("EmailNotification", emailNotificationSchema);
