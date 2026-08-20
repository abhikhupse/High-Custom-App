const SEQUENCE_COLLECTION = require("../model/sequence.model");
const LEADS_COLLECTION = require("../model/leads.model");
const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");
const crypto = require("crypto");

const { processSequencesForUser } = require("../jobs/sequence.job");

// ============================================================
// CREATE SEQUENCE
// ============================================================

// ============================================================
// CREATE SEQUENCE
// ============================================================

// ============================================================
// CREATE SEQUENCE
// ============================================================

exports.createSequence = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required",
      });
    }

    const {
      step,
      gapDays,
      variant,
      type,
      subject,
      brand,
      heroImage,
      content,
      editor,
      attachment,
      actionLinks,
      tracking,
      status,
      scheduledAt,
      statistics,
    } = req.body;

    // ==========================================================
    // FILES
    // ==========================================================

    const brandLogoFile = req.files?.brandLogo?.[0] || null;

    const heroImageFile = req.files?.heroImage?.[0] || null;

    const attachmentFile = req.files?.attachment?.[0] || null;

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (step === undefined || step === null || step === "") {
      return res.status(400).json({
        success: false,
        message: "Step is required",
      });
    }

    const stepNumber = Number(step);

    if (!Number.isInteger(stepNumber) || stepNumber < 1) {
      return res.status(400).json({
        success: false,
        message: "Step must be a valid number greater than 0",
      });
    }

    const gapDaysNumber = Number(gapDays || 0);

    if (!Number.isInteger(gapDaysNumber) || gapDaysNumber < 0) {
      return res.status(400).json({
        success: false,
        message: "Gap days must be a valid number greater than or equal to 0",
      });
    }

    if (!variant || typeof variant !== "string") {
      return res.status(400).json({
        success: false,
        message: "Variant is required",
      });
    }

    const formattedVariant = variant.trim().toUpperCase();

    if (!type || type === "Select Type") {
      return res.status(400).json({
        success: false,
        message: "Sequence type is required",
      });
    }

    if (!subject || typeof subject !== "string" || subject.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "Email subject is required",
      });
    }

    const formattedSubject = subject.trim();

    if (content === undefined || content === null) {
      return res.status(400).json({
        success: false,
        message: "Email content is required",
      });
    }

    // ==========================================================
    // DUPLICATE
    // ==========================================================

    const existingSequence = await SEQUENCE_COLLECTION.findOne({
      userId,
      step: stepNumber,
      variant: formattedVariant,
    });

    if (existingSequence) {
      return res.status(409).json({
        success: false,
        message: "Sequence already exists",
      });
    }

    // ==========================================================
    // BASE URL
    // ==========================================================

    const baseUrl = `${req.protocol}://${req.get("host")}`;

    // ==========================================================
    // LOGO
    // ==========================================================

    let logoUrl = null;

    if (brandLogoFile) {
      logoUrl = `${baseUrl}/uploads/brand/${brandLogoFile.filename}`;
    }

    const logoEnabled = Boolean(brandLogoFile);

    // ==========================================================
    // HERO
    // ==========================================================

    let heroUrl = null;

    if (heroImageFile) {
      heroUrl = `${baseUrl}/uploads/hero/${heroImageFile.filename}`;
    }

    const heroEnabled = Boolean(heroImageFile);

    // ==========================================================
    // ATTACHMENT
    // ==========================================================

    let attachmentData = {
      enabled: false,
      name: null,
      url: null,
      mimeType: null,
      size: 0,
    };

    if (attachmentFile) {
      attachmentData = {
        enabled: true,

        name: attachmentFile.originalname,

        url: `${baseUrl}/uploads/attachments/${attachmentFile.filename}`,

        mimeType: attachmentFile.mimetype,

        size: attachmentFile.size,
      };
    }

    // ==========================================================
    // WHATSAPP
    // ==========================================================

    let whatsappUrl = null;

    if (typeof actionLinks?.whatsapp === "string") {
      const cleanedWhatsapp = actionLinks.whatsapp.trim();

      if (
        cleanedWhatsapp !== "" &&
        (cleanedWhatsapp.startsWith("https://") ||
          cleanedWhatsapp.startsWith("http://"))
      ) {
        whatsappUrl = cleanedWhatsapp;
      }
    }

    const whatsappEnabled = Boolean(whatsappUrl);

    // ==========================================================
    // CTA
    // ==========================================================

    let ctaData = {
      enabled: false,
      text: null,
      url: null,
    };

    if (actionLinks?.cta && typeof actionLinks.cta === "object") {
      const ctaText =
        typeof actionLinks.cta.text === "string"
          ? actionLinks.cta.text.trim()
          : "";

      const ctaUrl =
        typeof actionLinks.cta.url === "string"
          ? actionLinks.cta.url.trim()
          : "";

      if (
        ctaText !== "" &&
        (ctaUrl.startsWith("https://") || ctaUrl.startsWith("http://"))
      ) {
        ctaData = {
          enabled: true,
          text: ctaText,
          url: ctaUrl,
        };
      }
    }

    // ==========================================================
    // CREATE
    // ==========================================================

    const sequence = await SEQUENCE_COLLECTION.create({
      userId,

      step: stepNumber,

      gapDays: gapDaysNumber,

      variant: formattedVariant,

      type,

      subject: formattedSubject,

      // ======================================================
      // BRAND
      // ======================================================

      brand: {
        enabled: logoEnabled,

        logoUrl,

        logoPosition: brand?.logoPosition || "Center",
      },

      // ======================================================
      // HERO
      // ======================================================

      heroImage: {
        enabled: heroEnabled,

        url: heroUrl,

        link: heroEnabled && heroImage?.link ? heroImage.link : null,
      },

      // ======================================================
      // CONTENT
      // ======================================================

      content,

      // ======================================================
      // EDITOR
      // ======================================================

      editor: {
        font: editor?.font || "Arial",

        fontSize: editor?.fontSize || "16px",

        textColor: editor?.textColor || "Black",

        bold: editor?.bold ?? false,

        italic: editor?.italic ?? false,

        underline: editor?.underline ?? false,
      },

      // ======================================================
      // ATTACHMENT
      // ======================================================

      attachment: attachmentData,

      // ======================================================
      // ACTION LINKS
      // ======================================================

      actionLinks: {
        whatsapp: {
          enabled: whatsappEnabled,

          url: whatsappUrl,
        },

        cta: ctaData,
      },

      // ======================================================
      // TRACKING
      // ======================================================

      tracking: {
        enabled: tracking?.enabled ?? true,

        trackingId: tracking?.trackingId || crypto.randomUUID(),
      },

      status: status || "draft",

      scheduledAt: scheduledAt || null,

      statistics: {
        sent: statistics?.sent || 0,

        delivered: statistics?.delivered || 0,

        opened: statistics?.opened || 0,

        clicked: statistics?.clicked || 0,

        failed: statistics?.failed || 0,

        interested: statistics?.interested || 0,

        notInterested: statistics?.notInterested || 0,
      },
    });

    return res.status(201).json({
      success: true,

      message: "Sequence Created Successfully",

      data: sequence,
    });
  } catch (error) {
    console.error("Error while creating Sequence:", error);

    if (error.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({
        success: false,
        message: "Uploaded file is too large",
      });
    }

    if (error.code === "LIMIT_FILE_COUNT") {
      return res.status(400).json({
        success: false,
        message: "Too many files uploaded",
      });
    }

    if (error.code === "LIMIT_UNEXPECTED_FILE") {
      return res.status(400).json({
        success: false,
        message: "Unexpected file field",
      });
    }

    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "A sequence with this step and variant already exists",
      });
    }

    if (error.name === "ValidationError") {
      const errors = Object.values(error.errors || {}).map(
        (err) => err.message,
      );

      return res.status(400).json({
        success: false,
        message: "Validation failed",
        errors,
      });
    }

    if (error.name === "CastError") {
      return res.status(400).json({
        success: false,
        message: `Invalid value for ${error.path}`,
      });
    }

    return res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
    });
  }
};

// ============================================================
// GET SEQUENCES
// ============================================================

// ============================================================
// GET TRACKING SUMMARY
// ============================================================

exports.getTrackingSummary = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?._id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User Authentication Required",
      });
    }

    // ========================================================
    // DATE FILTER
    // ========================================================

    const { startDate, endDate } = req.query;

    let start;
    let end;

    // ========================================================
    // START DATE
    // ========================================================

    if (startDate) {
      start = new Date(startDate);

      if (isNaN(start.getTime())) {
        return res.status(400).json({
          success: false,
          message: "Invalid startDate.",
        });
      }

      start.setHours(0, 0, 0, 0);
    }

    // ========================================================
    // END DATE
    // ========================================================

    if (endDate) {
      end = new Date(endDate);

      if (isNaN(end.getTime())) {
        return res.status(400).json({
          success: false,
          message: "Invalid endDate.",
        });
      }

      end.setHours(23, 59, 59, 999);
    }

    // ========================================================
    // BASE DELIVERY QUERY
    // ========================================================

    const deliveryQuery = {
      userId,
    };

    // ========================================================
    // DATE QUERY
    // ========================================================

    if (start || end) {
      deliveryQuery.createdAt = {};

      if (start) {
        deliveryQuery.createdAt.$gte = start;
      }

      if (end) {
        deliveryQuery.createdAt.$lte = end;
      }
    }

    // ========================================================
    // GET DELIVERIES
    // ========================================================

    const deliveries = await SEQUENCE_DELIVERY.find(deliveryQuery).lean();

    // ========================================================
    // CALCULATE STATISTICS
    // ========================================================

    let totalMails = 0;
    let sent = 0;
    let failed = 0;
    let opened = 0;
    let pending = 0;

    for (const delivery of deliveries) {
      totalMails++;

      // ------------------------------------------------------
      // SENT
      // ------------------------------------------------------

      if (delivery.status === "sent") {
        sent++;
      }

      // ------------------------------------------------------
      // FAILED
      // ------------------------------------------------------

      if (delivery.status === "failed") {
        failed++;
      }

      // ------------------------------------------------------
      // PENDING
      // ------------------------------------------------------

      if (delivery.status === "pending") {
        pending++;
      }

      // ------------------------------------------------------
      // OPENED
      // ------------------------------------------------------

      if (delivery.openedAt) {
        opened++;
      }
    }

    // ========================================================
    // TOTAL LEADS
    // ========================================================

    const totalLeads = await LEADS_COLLECTION.countDocuments({
      userId,
    });

    // ========================================================
    // TODAY LEADS
    // ========================================================

    const now = new Date();

    const todayStart = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      0,
      0,
      0,
      0,
    );

    const todayEnd = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      23,
      59,
      59,
      999,
    );

    const todayLeads = await LEADS_COLLECTION.countDocuments({
      userId,

      createdAt: {
        $gte: todayStart,
        $lte: todayEnd,
      },
    });

    // ========================================================
    // ACTIVE SEQUENCES
    // ========================================================

    const activeSequences = await SEQUENCE_COLLECTION.countDocuments({
      userId,
      status: "active",
    });

    // ========================================================
    // CLICKED
    // ========================================================

    // Currently your delivery model does not show a click
    // tracking field in the code you sent.
    //
    // Keep this at 0 until click tracking is implemented.

    const clicked = 0;

    // ========================================================
    // INTERESTED
    // ========================================================

    // Not implemented yet in your delivery model.
    const interested = 0;

    // ========================================================
    // NOT INTERESTED
    // ========================================================

    // Not implemented yet in your delivery model.
    const notInterested = 0;

    // ========================================================
    // RESPONSE
    // ========================================================

    return res.status(200).json({
      success: true,

      message: "Tracking summary fetched successfully",

      data: {
        totalMails,

        totalLeads,

        todayLeads,

        sent,

        failed,

        opened,

        clicked,

        pending,

        interested,

        notInterested,

        activeSequences,
      },
    });
  } catch (error) {
    console.error("Error while fetching tracking summary:", error);

    return res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
    });
  }
};

exports.getSequence = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User Authentication Required",
      });
    }

    const page = Math.max(Number.parseInt(req.query.page, 10) || 1, 1);

    const limit = Math.min(
      Math.max(Number.parseInt(req.query.limit, 10) || 10, 1),
      100,
    );

    const skip = (page - 1) * limit;

    const search =
      typeof req.query.search === "string" ? req.query.search.trim() : "";

    const status =
      typeof req.query.status === "string" ? req.query.status.trim() : "";

    const query = {
      userId,
    };

    if (search) {
      query.$or = [
        {
          subject: {
            $regex: search,
            $options: "i",
          },
        },
        {
          variant: {
            $regex: search,
            $options: "i",
          },
        },
        {
          type: {
            $regex: search,
            $options: "i",
          },
        },
        {
          content: {
            $regex: search,
            $options: "i",
          },
        },
      ];
    }

    if (status) {
      query.status = status;
    }

    const total = await SEQUENCE_COLLECTION.countDocuments(query);

    const sequences = await SEQUENCE_COLLECTION.find(query)
      .sort({
        step: 1,
        createdAt: -1,
      })
      .skip(skip)
      .limit(limit)
      .lean();

    const totalPages = Math.ceil(total / limit);

    return res.status(200).json({
      success: true,
      message: "Sequences fetched successfully",
      data: sequences,
      pagination: {
        page,
        limit,
        total,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      },
    });
  } catch (error) {
    console.error("Error While Fetching Sequences", error);

    if (error.name === "CastError") {
      return res.status(400).json({
        success: false,
        message: `Invalid value for ${error.path}`,
      });
    }

    return res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
    });
  }
};

// ============================================================
// MANUALLY RUN SEQUENCE JOB
// ============================================================

exports.runSequence = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required",
      });
    }

    console.log("==============================================");
    console.log("MANUAL SEQUENCE JOB REQUEST");
    console.log("USER:", userId);
    console.log("TIME:", new Date().toISOString());
    console.log("==============================================");

    const result = await processSequencesForUser(userId);

    return res.status(200).json({
      success: true,
      message: "Sequence job executed successfully",
      data: result,
    });
  } catch (error) {
    console.error("Manual sequence job error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to execute sequence job",
      error: error.message,
    });
  }
};
