const mongoose = require("mongoose");

const socialLinkSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    name: { type: String, required: true, trim: true, maxlength: 100 },
    url: { type: String, required: true, trim: true, maxlength: 2048 },
    category: {
      type: String,
      enum: ["social", "ecommerce", "payment", "custom"],
      default: "custom",
    },
    platform: { type: String, default: "", trim: true },
    selected: { type: Boolean, default: false },
    qrCode: { type: String, default: "" },
    qrTarget: { type: String, default: "" },
    qrGeneratedAt: { type: Date },
    linkClicks: { type: Number, default: 0, min: 0 },
    qrScans: { type: Number, default: 0, min: 0 },
  },
  { timestamps: true },
);

module.exports = mongoose.model("Social Link", socialLinkSchema);
