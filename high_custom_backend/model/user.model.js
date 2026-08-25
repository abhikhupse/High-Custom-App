const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    firstName: {
      type: String,
      required: true,
      trim: true,
    },

    lastName: {
      type: String,
      required: true,
      trim: true,
    },

    employerCode: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },

    phone: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },

    profileImage: {
      type: String,
      default: null,
      trim: true,
    },

    password: {
      type: String,
      required: true,
    },

    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    isLogIn: {
      type: Boolean,
      default: false,
    },

    loginDeviceIps: {
      type: [
        {
          ipAddress: {
            type: String,
            required: true,
            trim: true,
          },
          userAgent: {
            type: String,
            default: "",
          },
          lastSeenAt: {
            type: Date,
            default: Date.now,
          },
        },
      ],
      default: [],
    },

    emailOtp: {
      type: String,
      default: null,
    },

    emailOtpExpires: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  },
);

module.exports = mongoose.model("User", userSchema);
