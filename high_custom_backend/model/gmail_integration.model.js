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
  },

  {
    timestamps: true,
  },
);

module.exports = mongoose.model("GmailIntegration", gmailIntegrationSchema);
