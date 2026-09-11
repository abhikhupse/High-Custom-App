const mongoose = require("mongoose");

const businessCardSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
    index: true,
  },
  fullName: {
    type: String,
    required: true,
  },
  role: {
    type: String,
    required: true,
  },
  companyName: {
    type: String,
    required: true,
  },
  whatsapp: {
    // Phone numbers are identifiers, not numeric values. Keeping this as a
    // string preserves leading zeroes and avoids cast errors from +91 input.
    type: String,
    required: true,
    minlength: 10,
    maxlength: 10,
    trim: true,
  },
  email: {
    type: String,
    required: true,
    trim: true,
  },

  qrLink: {
    type: String,
    required: true,
    trim: true,
  },
  qrCode: {
    type: String,
    required: true,
  },
  address: {
    type: String,
    required: true,
  },
});

module.exports = mongoose.model("Business Card", businessCardSchema);
