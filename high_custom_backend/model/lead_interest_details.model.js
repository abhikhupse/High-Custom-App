const mongoose = require("mongoose");

const leadInterestDetailsSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    leadId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Leads",
      required: true,
      index: true,
    },
    sequenceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Sequence",
      required: true,
      index: true,
    },
    trackingId: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    name: { type: String, required: true, trim: true, maxlength: 160 },
    mobileNumber: { type: String, required: true, trim: true, maxlength: 30 },
    companyName: { type: String, trim: true, default: "", maxlength: 160 },
    city: { type: String, required: true, trim: true, maxlength: 100 },
    state: { type: String, required: true, trim: true, maxlength: 100 },
    country: { type: String, required: true, trim: true, maxlength: 100 },
    status: {
      type: String,
      enum: ["interested"],
      default: "interested",
    },
    submittedAt: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

leadInterestDetailsSchema.index({ userId: 1, submittedAt: -1 });

module.exports = mongoose.model(
  "LeadInterestDetails",
  leadInterestDetailsSchema,
  "lead_interest_details",
);
