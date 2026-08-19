const SEQUENCE_COLLECTION = require("../model/sequence.model");
const LEADS_COLLECTION = require("../model/leads.model");
const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");
const crypto = require("crypto");

const { processSequencesForUser } = require("../jobs/sequence.job");

// ============================================================
// CREATE SEQUENCE
// ============================================================

exports.createSequence = async (req, res) => {
  try {
    // ==========================================================
    // GET AUTHENTICATED USER
    // ==========================================================

    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required",
      });
    }

    // ==========================================================
    // GET BODY DATA
    // ==========================================================

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
    // GET MULTER FILES
    // ==========================================================

    const brandLogoFile = req.files?.brandLogo?.[0] || null;

    const heroImageFile = req.files?.heroImage?.[0] || null;

    const attachmentFile = req.files?.attachment?.[0] || null;

    // ==========================================================
    // BASIC VALIDATION
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

    // ==========================================================
    // GAP DAYS
    // ==========================================================

    if (gapDays === undefined || gapDays === null || gapDays === "") {
      return res.status(400).json({
        success: false,
        message: "Gap days is required",
      });
    }

    const gapDaysNumber = Number(gapDays);

    if (!Number.isInteger(gapDaysNumber) || gapDaysNumber < 0) {
      return res.status(400).json({
        success: false,
        message: "Gap days must be a valid number greater than or equal to 0",
      });
    }

    // ==========================================================
    // VARIANT
    // ==========================================================

    if (!variant || typeof variant !== "string" || variant.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "Variant is required",
      });
    }

    const formattedVariant = variant.trim().toUpperCase();

    // ==========================================================
    // TYPE
    // ==========================================================

    if (!type || type === "Select Type") {
      return res.status(400).json({
        success: false,
        message: "Sequence type is required",
      });
    }

    // ==========================================================
    // SUBJECT
    // ==========================================================

    if (!subject || typeof subject !== "string" || subject.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "Email subject is required",
      });
    }

    const formattedSubject = subject.trim();

    // ==========================================================
    // CONTENT
    // ==========================================================

    if (content === undefined || content === null) {
      return res.status(400).json({
        success: false,
        message: "Email content is required",
      });
    }

    // ==========================================================
    // CHECK DUPLICATE SEQUENCE
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
    // BRAND LOGO URL
    // ==========================================================

    let logoUrl = null;

    if (brandLogoFile) {
      logoUrl = `${baseUrl}/uploads/brand/${brandLogoFile.filename}`;
    }

    // ==========================================================
    // HERO IMAGE URL
    // ==========================================================

    let heroUrl = null;

    if (heroImageFile) {
      heroUrl = `${baseUrl}/uploads/hero/${heroImageFile.filename}`;
    }

    // ==========================================================
    // ATTACHMENT URL
    // ==========================================================

    let attachmentUrl = null;

    if (attachmentFile) {
      attachmentUrl = `${baseUrl}/uploads/attachments/${attachmentFile.filename}`;
    }

    // ==========================================================
    // TRACKING
    // ==========================================================

    const trackingData = {
      enabled: tracking?.enabled ?? true,
      trackingId: tracking?.trackingId || crypto.randomUUID(),
    };

    // ==========================================================
    // CREATE SEQUENCE
    // ==========================================================

    const sequence = await SEQUENCE_COLLECTION.create({
      userId,

      step: stepNumber,

      gapDays: gapDaysNumber,

      variant: formattedVariant,

      type,

      subject: formattedSubject,

      brand: {
        logoUrl: logoUrl || brand?.logoUrl || null,
        logoPosition: brand?.logoPosition || "Center",
      },

      heroImage: {
        url: heroUrl || heroImage?.url || null,
        link: heroImage?.link || null,
      },

      content,

      editor: {
        font: editor?.font || "Arial",
        fontSize: editor?.fontSize || "16px",
        textColor: editor?.textColor || "Black",
        bold: editor?.bold ?? false,
        italic: editor?.italic ?? false,
        underline: editor?.underline ?? false,
      },

      attachment: {
        name: attachmentFile
          ? attachmentFile.originalname
          : attachment?.name || null,

        url: attachmentUrl || attachment?.url || null,

        mimeType: attachmentFile
          ? attachmentFile.mimetype
          : attachment?.mimeType || null,

        size: attachmentFile ? attachmentFile.size : attachment?.size || 0,
      },

      actionLinks: {
        whatsapp: actionLinks?.whatsapp || null,
      },

      tracking: trackingData,

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

    if (
      error.message &&
      (error.message.includes("Brand logo") ||
        error.message.includes("Hero image") ||
        error.message.includes("attachment") ||
        error.message.includes("Unexpected file"))
    ) {
      return res.status(400).json({
        success: false,
        message: error.message,
      });
    }

    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "A sequence with this step and variant already exists",
      });
    }

    if (error.name === "ValidationError") {
      const errors = Object.values(error.errors).map((err) => err.message);

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
