const mongoose = require("mongoose");

const leadsSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    id: {},

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

module.exports = mongoose.model("Leads", leadsSchema);
