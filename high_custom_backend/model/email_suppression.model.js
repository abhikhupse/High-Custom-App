const mongoose = require("mongoose");
const schema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, required: true },
  email: { type: String, required: true, lowercase: true, trim: true },
  reason: { type: String, enum: ["unsubscribe", "hard_bounce"], required: true },
}, { timestamps: true });
schema.index({ userId: 1, email: 1 }, { unique: true });
module.exports = mongoose.model("EmailSuppression", schema);
