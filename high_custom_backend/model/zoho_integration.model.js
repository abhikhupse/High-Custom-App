const mongoose = require("mongoose");

const zohoIntegrationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true,
      index: true,
    },
    email: { type: String, required: true, trim: true, lowercase: true },
    accountId: { type: String, required: true },
    accessToken: { type: String, required: true },
    refreshToken: { type: String, required: true },
    apiDomain: { type: String, default: null },
    scope: { type: String, default: "" },
    tokenType: { type: String, default: "Bearer" },
    expiresAt: { type: Date, default: null },
    connectedAt: { type: Date, default: Date.now },
    lastSyncAt: { type: Date, default: Date.now },
    syncLockUntil: { type: Date, default: null },
    lastSyncError: { type: String, default: null },
  },
  { timestamps: true },
);

zohoIntegrationSchema.index({ email: 1 });

module.exports = mongoose.model("ZohoIntegration", zohoIntegrationSchema);
