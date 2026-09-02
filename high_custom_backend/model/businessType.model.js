const mongoose = require("mongoose");

const businessTypeSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
      maxlength: 100,
    },
    normalizedName: {
      type: String,
      required: true,
      trim: true,
    },
  },
  { timestamps: true },
);

businessTypeSchema.index(
  { userId: 1, normalizedName: 1 },
  { unique: true },
);

module.exports = mongoose.model("BusinessType", businessTypeSchema);
