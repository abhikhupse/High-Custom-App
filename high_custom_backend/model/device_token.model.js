const mongoose = require("mongoose");

const deviceTokenSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    token: { type: String, required: true, unique: true, trim: true },
    platform: { type: String, enum: ["android", "ios"], default: "android" },
    lastSeenAt: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

module.exports = mongoose.model("DeviceToken", deviceTokenSchema);
