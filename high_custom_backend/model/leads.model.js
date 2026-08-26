const mongoose = require("mongoose");

const leadsSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    // id: {},

    firstName: {
      type: String,
      trim: true,
      default: "",
    },

    lastName: {
      type: String,
      trim: true,
      default: "",
    },

    email: {
      type: String,
      required: true,
      trim: true,
      lowercase: true,
    },

    company: {
      type: String,
      trim: true,
      default: "",
    },

    // Email / WhatsApp
    type: {
      type: String,
      enum: ["Email", "WhatsApp"],
      default: "Email",
    },

    businessType: {
      type: String,
      trim: true,
      default: "",
      maxlength: 100,
      index: true,
    },

    tracking: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  },
);

// Same email can exist for different users,
// but not twice for the same user.
leadsSchema.index(
  {
    userId: 1,
    email: 1,
  },
  {
    unique: true,
  },
);

// Sequence workers filter by all four fields together. Keeping userId first
// also isolates each tenant's data efficiently.
leadsSchema.index({
  userId: 1,
  type: 1,
  businessType: 1,
  tracking: 1,
  _id: 1,
});

// Supports the newest-first leads screen without an in-memory sort.
leadsSchema.index({
  userId: 1,
  createdAt: -1,
});

module.exports = mongoose.model("Leads", leadsSchema);
