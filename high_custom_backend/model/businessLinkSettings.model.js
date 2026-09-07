const mongoose = require("mongoose");

const businessLinkSettingsSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    businessType: { type: String, required: true, trim: true },
    logoKey: { type: String, default: "high_custom_logo" },
    logoUrl: { type: String, default: "" },
    whatsappUrl: { type: String, required: true, trim: true },
    actionLinkIds: [{ type: mongoose.Schema.Types.ObjectId, ref: "Social Link" }],
    actionLinkNames: [{ type: String, trim: true }],
    actionLinks: [{
      id: { type: mongoose.Schema.Types.ObjectId, ref: "Social Link" },
      name: { type: String, trim: true },
      url: { type: String, trim: true },
    }],
  },
  { timestamps: true },
);
businessLinkSettingsSchema.index({ userId: 1, businessType: 1 }, { unique: true });
module.exports = mongoose.model("Business Link Settings", businessLinkSettingsSchema);
