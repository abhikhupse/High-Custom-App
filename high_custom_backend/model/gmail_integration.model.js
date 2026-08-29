const mongoose = require("mongoose");

const gmailIntegrationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,

      ref: "User",

      required: true,

      unique: true,

      index: true,
    },

    email: {
      type: String,

      required: true,

      trim: true,

      lowercase: true,
    },

    accessToken: {
      type: String,

      required: true,
    },

    refreshToken: {
      type: String,

      required: true,
    },

    scope: {
      type: String,

      default: "",
    },

    tokenType: {
      type: String,

      default: "Bearer",
    },

    expiryDate: {
      type: Number,

      default: null,
    },

    connectedAt: {
      type: Date,

      default: Date.now,
    },

    // Gmail push-notification cursor and watch lifecycle.
    lastHistoryId: {
      type: String,
      default: null,
    },

    watchExpiration: {
      type: Date,
      default: null,
    },

    watchLastRenewedAt: {
      type: Date,
      default: null,
    },

    replySyncLockUntil: {
      type: Date,
      default: null,
    },

    replySyncLastCompletedAt: {
      type: Date,
      default: null,
    },

    replySyncLastError: {
      type: String,
      default: null,
    },

    replySyncPendingHistoryId: {
      type: String,
      default: null,
    },
  },

  {
    timestamps: true,
  },
);

gmailIntegrationSchema.index({ email: 1 });
gmailIntegrationSchema.index({ watchExpiration: 1 });

module.exports = mongoose.model("GmailIntegration", gmailIntegrationSchema);
