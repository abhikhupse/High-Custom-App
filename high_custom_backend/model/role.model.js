const mongoose = require("mongoose");

// Custom employee roles created by the main Administrator, for example Sales
// or Marketing. Core roles (Admin, HR, Employee) stay in code.
const roleSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      unique: true,
      maxlength: 49,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  { timestamps: true },
);

module.exports = mongoose.model("Role", roleSchema);
