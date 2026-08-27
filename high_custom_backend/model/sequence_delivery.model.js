const mongoose = require("mongoose");

const sequenceDeliverySchema = new mongoose.Schema(
  {
    // ============================================================
    // USER
    // ============================================================

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    // ============================================================
    // LEAD
    // ============================================================

    leadId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Leads",
      required: true,
      index: true,
    },

    // ============================================================
    // SEQUENCE
    // ============================================================

    sequenceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Sequence",
      required: true,
      index: true,
    },

    // ============================================================
    // STEP
    // ============================================================

    step: {
      type: Number,
      required: true,
    },

    // ============================================================
    // VARIANT
    // ============================================================

    variant: {
      type: String,
      required: true,
      trim: true,
      uppercase: true,
    },

    // ============================================================
    // SEQUENCE TYPE
    // ============================================================

    sequenceType: {
      type: String,
      required: true,
    },

    // ============================================================
    // LEAD TYPE
    // ============================================================

    leadType: {
      type: String,
      required: true,
    },

    // ============================================================
    // STATUS
    // ============================================================

    status: {
      type: String,
      enum: ["pending", "sent", "failed"],
      default: "pending",
      index: true,
    },

    // ============================================================
    // TRACKING
    // ============================================================

    trackingId: {
      type: String,
      default: null,
      index: true,
    },

    // ============================================================
    // SCHEDULE
    // ============================================================

    scheduledAt: {
      type: Date,
      default: null,
    },

    // ============================================================
    // SENT
    // ============================================================

    sentAt: {
      type: Date,
      default: null,
    },

    // ============================================================
    // ERROR
    // ============================================================

    errorMessage: {
      type: String,
      default: null,
    },

    // ============================================================
    // EMAIL MESSAGE
    // ============================================================

    messageId: {
      type: String,
      default: null,
    },

    threadId: {
      type: String,
      default: null,
    },

    // ============================================================
    // OPEN TRACKING
    // ============================================================

    openedAt: {
      type: Date,
      default: null,
    },

    openedCount: {
      type: Number,
      default: 0,
    },

    // ============================================================
    // CLICK TRACKING
    // ============================================================

    clickedAt: {
      type: Date,
      default: null,
    },

    response: {
      type: String,
      enum: ["interested", "notInterested"],
      default: null,
    },

    respondedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  },
);

// ============================================================
// PREVENT DUPLICATE DELIVERY
// ============================================================

sequenceDeliverySchema.index(
  {
    leadId: 1,
    sequenceId: 1,
  },
  {
    unique: true,
  },
);

sequenceDeliverySchema.index({
  userId: 1,
  createdAt: -1,
});

sequenceDeliverySchema.index({
  userId: 1,
  sequenceId: 1,
  createdAt: -1,
});

sequenceDeliverySchema.index({
  userId: 1,
  status: 1,
  createdAt: -1,
});

sequenceDeliverySchema.index({
  sequenceId: 1,
  status: 1,
});

module.exports = mongoose.model("SequenceDelivery", sequenceDeliverySchema);
