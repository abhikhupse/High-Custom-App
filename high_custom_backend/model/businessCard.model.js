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
    type: Number,
    required: true,
    minLength: 10,
    maxLength: 10,
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
