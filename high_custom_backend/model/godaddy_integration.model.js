const mongoose = require("mongoose");

const goDaddyIntegrationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true,
      index: true,
    },
    email: { type: String, required: true, trim: true, lowercase: true },
    senderName: { type: String, default: "", trim: true },
    passwordCiphertext: { type: String, required: true, select: false },
    passwordIv: { type: String, required: true, select: false },
    passwordAuthTag: { type: String, required: true, select: false },
    connectedAt: { type: Date, default: Date.now },
    lastVerifiedAt: { type: Date, default: Date.now },
    lastError: { type: String, default: null },
    lastReplySyncAt: { type: Date, default: null },
    replySyncLockUntil: { type: Date, default: null },
    replySyncLastError: { type: String, default: null },
  },
  { timestamps: true },
);

goDaddyIntegrationSchema.index({ email: 1 });

module.exports = mongoose.model("GoDaddyIntegration", goDaddyIntegrationSchema);
