const mongoose = require("mongoose");

const sequenceSchema = new mongoose.Schema(
  {
    // USER

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    // BASIC INFORMATION

    step: {
      type: Number,
      required: true,
      min: 1,
    },

    gapDays: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },

    variant: {
      type: String,
      required: true,
      trim: true,
      uppercase: true,
      maxlength: 10,
    },

    type: {
      type: String,
      required: true,
      enum: ["Email", "Follow Up", "Promotion", "Reminder"],
    },

    // EMAIL SUBJECT

    subject: {
      type: String,
      required: true,
      trim: true,
      maxlength: 500,
    },

    // BRAND IDENTITY

    brand: {
      logoUrl: {
        type: String,
        default: null,
      },

      logoPosition: {
        type: String,
        enum: ["Left", "Center", "Right"],
        default: "Center",
      },
    },

    // HERO IMAGE

    heroImage: {
      url: {
        type: String,
        default: null,
      },

      link: {
        type: String,
        default: null,
      },
    },

    // EMAIL CONTENT

    content: {
      type: String,
      required: true,
      default: "",
    },

    // EMAIL EDITOR SETTINGS

    editor: {
      font: {
        type: String,
        enum: ["Arial", "Roboto", "Verdana"],
        default: "Arial",
      },

      fontSize: {
        type: String,
        enum: ["12px", "14px", "16px", "18px", "20px"],
        default: "16px",
      },

      textColor: {
        type: String,
        enum: ["Black", "Red", "Blue", "Green"],
        default: "Black",
      },

      bold: {
        type: Boolean,
        default: false,
      },

      italic: {
        type: Boolean,
        default: false,
      },

      underline: {
        type: Boolean,
        default: false,
      },
    },

    // ATTACHMENT

    attachment: {
      name: {
        type: String,
        default: null,
      },

      url: {
        type: String,
        default: null,
      },

      mimeType: {
        type: String,
        default: null,
      },

      size: {
        type: Number,
        default: 0,
      },
    },

    // ACTION LINKS / CTA

    actionLinks: {
      whatsapp: {
        type: String,
        default: null,
      },
    },

    // EMAIL TRACKING

    tracking: {
      enabled: {
        type: Boolean,
        default: true,
      },

      trackingId: {
        type: String,
        default: null,
        index: true,
      },
    },

    // ============================================================
    // STATUS
    // ============================================================

    status: {
      type: String,
      enum: ["draft", "active", "paused", "completed"],
      default: "draft",
      index: true,
    },

    // ============================================================
    // SCHEDULING
    // ============================================================

    scheduledAt: {
      type: Date,
      default: null,
    },

    // ============================================================
    // STATISTICS
    // ============================================================

    statistics: {
      sent: {
        type: Number,
        default: 0,
      },

      delivered: {
        type: Number,
        default: 0,
      },

      opened: {
        type: Number,
        default: 0,
      },

      clicked: {
        type: Number,
        default: 0,
      },

      failed: {
        type: Number,
        default: 0,
      },

      interested: {
        type: Number,
        default: 0,
      },

      notInterested: {
        type: Number,
        default: 0,
      },
    },
  },
  {
    timestamps: true,
  },
);

// ============================================================
// INDEXES
// ============================================================

// Quickly find all sequence steps belonging to a user.
sequenceSchema.index({
  userId: 1,
  step: 1,
});

// Quickly find active sequences.
sequenceSchema.index({
  userId: 1,
  status: 1,
});

// Prevent duplicate step + variant for the same user.
sequenceSchema.index(
  {
    userId: 1,
    step: 1,
    variant: 1,
  },
  {
    unique: true,
  },
);

module.exports = mongoose.model("Sequence", sequenceSchema);
