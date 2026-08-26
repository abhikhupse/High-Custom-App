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
    // ==========================================================
    // AUTH USER
    // ==========================================================

    const userId = req.user?.id || req.user?._id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required",
      });
    }

    // ==========================================================
    // BODY
    // ==========================================================

    const {
      step,
      gapDays,
      variant,
      type,
      channel,
      businessType,

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
    // PARSE JSON MULTIPART FIELDS
    // ==========================================================

    const parsedBrand = parseJsonField(brand, {});

    const parsedHeroImage = parseJsonField(heroImage, {});

    const parsedEditor = parseJsonField(editor, {});

    const parsedAttachment = parseJsonField(attachment, {});

    const parsedActionLinks = parseJsonField(actionLinks, {});

    const parsedTracking = parseJsonField(tracking, {});

    const parsedStatistics = parseJsonField(statistics, {});

    // ==========================================================
    // FILES
    // ==========================================================

    const brandLogoFile = req.files?.brandLogo?.[0] || null;

    const heroImageFile = req.files?.heroImage?.[0] || null;

    const attachmentFile = req.files?.attachment?.[0] || null;

    // ==========================================================
    // STEP VALIDATION
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

    const gapDaysNumber =
      gapDays === undefined || gapDays === null || gapDays === ""
        ? 0
        : Number(gapDays);

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
    // BUSINESS TYPE
    // ==========================================================

    const rawBusinessType = businessType ?? type;

    if (
      !rawBusinessType ||
      typeof rawBusinessType !== "string" ||
      rawBusinessType.trim() === ""
    ) {
      return res.status(400).json({
        success: false,
        message: "Business type is required",
      });
    }

    const formattedBusinessType = rawBusinessType.trim();

    const formattedChannel =
      typeof channel === "string" && channel.trim() === "Email"
        ? "Email"
        : "Email";

    if (formattedBusinessType.length < 2) {
      return res.status(400).json({
        success: false,
        message: "Business type must contain at least 2 characters",
      });
    }

    if (formattedBusinessType.length > 100) {
      return res.status(400).json({
        success: false,
        message: "Business type cannot exceed 100 characters",
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

    if (
      content === undefined ||
      content === null ||
      typeof content !== "string" ||
      content.trim() === ""
    ) {
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
        message: "A sequence with this step and variant already exists",
      });
    }

    // ==========================================================
    // BASE URL
    // ==========================================================

    const baseUrl = `${req.protocol}://${req.get("host")}`;

    // ==========================================================
    // BRAND / LOGO
    // ==========================================================

    let logoUrl = null;

    if (brandLogoFile) {
      logoUrl = `${baseUrl}/uploads/brand/${brandLogoFile.filename}`;
    }

    const logoEnabled = Boolean(brandLogoFile);

    const logoPosition = ["Left", "Center", "Right"].includes(
      parsedBrand?.logoPosition,
    )
      ? parsedBrand.logoPosition
      : "Center";

    // ==========================================================
    // HERO IMAGE
    // ==========================================================

    let heroUrl = null;

    if (heroImageFile) {
      heroUrl = `${baseUrl}/uploads/hero/${heroImageFile.filename}`;
    }

    const heroEnabled = Boolean(heroImageFile);

    let heroLink = null;

    if (typeof parsedHeroImage?.link === "string") {
      const cleanedHeroLink = parsedHeroImage.link.trim();

      if (
        cleanedHeroLink.startsWith("https://") ||
        cleanedHeroLink.startsWith("http://")
      ) {
        heroLink = cleanedHeroLink;
      }
    }

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
    } else if (parsedAttachment && typeof parsedAttachment === "object") {
      attachmentData = {
        enabled: false,
        name: parsedAttachment?.name || null,
        url: null,
        mimeType: parsedAttachment?.mimeType || null,
        size: Number(parsedAttachment?.size || 0),
      };
    }

    // ==========================================================
    // WHATSAPP
    // ==========================================================

    let whatsappUrl = null;

    let whatsappValue = null;

    if (typeof parsedActionLinks?.whatsapp === "string") {
      whatsappValue = parsedActionLinks.whatsapp;
    } else if (typeof parsedActionLinks?.whatsapp?.url === "string") {
      whatsappValue = parsedActionLinks.whatsapp.url;
    }

    if (whatsappValue) {
      const cleanedWhatsapp = whatsappValue.trim();

      if (
        cleanedWhatsapp.startsWith("https://") ||
        cleanedWhatsapp.startsWith("http://")
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

    if (parsedActionLinks?.cta && typeof parsedActionLinks.cta === "object") {
      const ctaText =
        typeof parsedActionLinks.cta.text === "string"
          ? parsedActionLinks.cta.text.trim()
          : "";

      const ctaUrl =
        typeof parsedActionLinks.cta.url === "string"
          ? parsedActionLinks.cta.url.trim()
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
    // EDITOR
    // ==========================================================

    const editorData = {
      font: parsedEditor?.font || "Arial",

      fontSize: parsedEditor?.fontSize || "16px",

      textColor: parsedEditor?.textColor || "Black",

      bold: toBoolean(parsedEditor?.bold, false),

      italic: toBoolean(parsedEditor?.italic, false),

      underline: toBoolean(parsedEditor?.underline, false),
    };

    // ==========================================================
    // TRACKING
    // ==========================================================

    const trackingEnabled = toBoolean(parsedTracking?.enabled, true);

    // ==========================================================
    // STATUS
    // ==========================================================

    const allowedStatuses = ["draft", "scheduled", "active", "paused"];

    const formattedStatus = allowedStatuses.includes(status) ? status : "draft";

    // ==========================================================
    // SCHEDULE DATE
    // ==========================================================

    let formattedScheduledAt = null;

    if (scheduledAt && typeof scheduledAt === "string") {
      const scheduleDate = new Date(scheduledAt);

      if (!Number.isNaN(scheduleDate.getTime())) {
        formattedScheduledAt = scheduleDate;
      }
    }

    if (formattedStatus === "scheduled" && !formattedScheduledAt) {
      return res.status(400).json({
        success: false,
        message: "Scheduled date and time is required when status is scheduled",
      });
    }

    // ==========================================================
    // CREATE SEQUENCE
    // ==========================================================

    const sequence = await SEQUENCE_COLLECTION.create({
      userId,

      step: stepNumber,

      gapDays: gapDaysNumber,

      variant: formattedVariant,

      // Delivery channel and business category are separate.
      type: formattedChannel,
      channel: formattedChannel,
      businessType: formattedBusinessType,

      subject: formattedSubject,

      // ======================================================
      // BRAND
      // ======================================================

      brand: {
        enabled: logoEnabled,

        logoUrl,

        logoPosition,
      },

      // ======================================================
      // HERO IMAGE
      // ======================================================

      heroImage: {
        enabled: heroEnabled,

        url: heroUrl,

        link: heroLink,
      },

      // ======================================================
      // CONTENT
      // ======================================================

      content: content,

      // ======================================================
      // EDITOR
      // ======================================================

      editor: editorData,

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
        enabled: trackingEnabled,

        trackingId: parsedTracking?.trackingId || crypto.randomUUID(),
      },

      // ======================================================
      // STATUS
      // ======================================================

      status: formattedStatus,

      scheduledAt: formattedScheduledAt,

      // ======================================================
      // STATISTICS
      // ======================================================

      statistics: {
        sent: Number(parsedStatistics?.sent || 0),

        delivered: Number(parsedStatistics?.delivered || 0),

        opened: Number(parsedStatistics?.opened || 0),

        clicked: Number(parsedStatistics?.clicked || 0),

        failed: Number(parsedStatistics?.failed || 0),

        interested: Number(parsedStatistics?.interested || 0),

        notInterested: Number(parsedStatistics?.notInterested || 0),
      },
    });

    // ==========================================================
    // PROCESS EXISTING LEADS FOR A NEW ACTIVE SEQUENCE
    // ==========================================================

    // Lead creation already runs active sequences, but the reverse flow also
    // needs to work: when an active sequence is created after leads already
    // exist, process those matching leads immediately.
    let execution = null;

    if (sequence.status === "active") {
      execution = await processSequencesForUser(userId);
    }

    // ==========================================================
    // RESPONSE
    // ==========================================================

    return res.status(201).json({
      success: true,
      message: "Sequence Created Successfully",
      data: sequence,
      execution,
    });
  } catch (error) {
    console.error("Error while creating Sequence:", error);

    // ==========================================================
    // MULTER
    // ==========================================================

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

    // ==========================================================
    // DUPLICATE
    // ==========================================================

    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "A sequence with this step and variant already exists",
      });
    }

    // ==========================================================
    // MONGOOSE VALIDATION
    // ==========================================================

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

    // ==========================================================
    // CAST ERROR
    // ==========================================================

    if (error.name === "CastError") {
      return res.status(400).json({
        success: false,
        message: `Invalid value for ${error.path}`,
      });
    }

    // ==========================================================
    // INTERNAL ERROR
    // ==========================================================

    return res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
    });
  }
};

// ============================================================
// PARSE JSON FIELD
// ============================================================

function parseJsonField(value, fallback = {}) {
  if (value === undefined || value === null || value === "") {
    return fallback;
  }

  if (typeof value === "object") {
    return value;
  }

  if (typeof value !== "string") {
    return fallback;
  }

  try {
    return JSON.parse(value);
  } catch (_) {
    return fallback;
  }
}

// ============================================================
// BOOLEAN CONVERTER
// ============================================================

function toBoolean(value, defaultValue = false) {
  if (value === undefined || value === null) {
    return defaultValue;
  }

  if (typeof value === "boolean") {
    return value;
  }

  if (typeof value === "string") {
    if (value.toLowerCase() === "true") {
      return true;
    }

    if (value.toLowerCase() === "false") {
      return false;
    }
  }

  return Boolean(value);
}

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
          businessType: {
            $regex: search,
            $options: "i",
          },
        },
        {
          // Backward compatibility for records created before businessType
          // was separated from the delivery channel.
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
      data: sequences.map((sequence) => ({
        ...sequence,
        channel: sequence.channel || "Email",
        type: sequence.channel || "Email",
        businessType:
          sequence.businessType ||
          (sequence.type && sequence.type !== "Email" ? sequence.type : ""),
      })),
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

exports.updateSequence = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const { sequenceId } = req.params;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "User Authrntication required",
      });
    }

    if (!sequenceId) {
      return res.status(400).json({
        success: false,
        message: "Sequence ID is required",
      });
    }

    const sequence = await SEQUENCE_COLLECTION.findOne({
      _id: sequenceId,
      userId,
    });

    if (!sequence) {
      return res.status(400).json({
        success: false,
        message: "Sequence not found",
      });
    }

    const {
      step,
      gapDays,
      variant,
      businessType,
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
    } = req.body;

    const parsedBrand = parseJsonField(brand, {});
    const parsedHeroImage = parseJsonField(heroImage, {});
    const parsedEditor = parseJsonField(editor, {});
    const parsedAttachment = parseJsonField(attachment, {});
    const parsedActionLinks = parseJsonField(actionLinks, {});
    const parsedTracking = parseJsonField(tracking, {});

    const stepNumber = Number(step);
    const gapDaysNumber = Number(gapDays ?? 0);

    if (!Number.isInteger(stepNumber) || stepNumber < 0) {
      return res.status(400).json({
        success: false,
        message: "Step Number must be greater than 0",
      });
    }

    if (!Number.isInteger(gapDaysNumber) || gapDaysNumber < 1) {
      return res.status(400).json({
        success: false,
        message: "Gap day must be 0 or greater than 0",
      });
    }

    const formattedVariant =
      typeof variant === "string" ? variant.trim().toUpperCase() : "";

    if (!formattedVariant) {
      return res.status(400).json({
        success: false,
        message: "Varient is required",
      });
    }

    const formattedBusinessType =
      typeof variant === "string" ? businessType.trim() : "";

    if (!formattedBusinessType) {
      return res.status(400).json({
        success: false,
        message: "Business type is required",
      });
    }

    const formattedSubject = typeof subject === "string" ? subject.trim() : "";

    if (!formattedSubject) {
      return res.status(400).json({
        success: false,
        message: "Subject is required",
      });
    }

    if (typeof content !== "string" || content.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "Email Content is required",
      });
    }

    const duplicate = await SEQUENCE_COLLECTION.findOne({
      userId,
      step: stepNumber,
      variant: formattedVariant,
      _id: {
        $ne: sequence._id,
      },
    });

    if (duplicate) {
      return res.status(400).json({
        success: false,
        message: "Another sequence with this step and variant already exists",
      });
    }

    const allowedStatuses = [
      "draft",
      "scheduled",
      "active",
      "paused",
      "completed",
    ];

    const formattedStatus = allowedStatuses.includes(status)
      ? status
      : sequence.status;

    if (scheduledAt && typeof scheduledAt === "string") {
      const date = new Date(scheduledAt);

      if (!Number.isNaN(date.getTime())) {
        formattedScheduledAt = date;
      }
    }
    if (formattedStatus === "schuduled" && !formattedScheduledAt) {
      return res.status(400).json({
        success: false,
        message: "Scheduled date and time is required",
      });
    }

    sequence.step = stepNumber;
    sequence.gapDays = gapDaysNumber;
    sequence.variant = formattedVariant;

    sequence.type = "Email";
    sequence.channel = "Email";
    sequence.businessType = formattedBusinessType;

    sequence.subject = formattedSubject;
    sequence.content = content;

    sequence.status = formattedStatus;
    sequence.scheduledAt =
      formattedStatus === "scheduled" ? formattedScheduledAt : null;

    if (parsedBrand && typeof parsedBrand === -"object") {
      const logoUrl =
        typeof parsedBrand.logoUrl === "string"
          ? parsedBrand.logoUrl.trim()
          : "";

      sequence.brand = {
        enabled: logoUrl !== "",
        logoUrl: logoUrl || null,
        logoPosition: ["Left", "Center", "Right"].includes(
          parsedBrand.logoPosition,
        )
          ? parsedBrand.logoPosition
          : "Center",
      };
    }

    if (parsedHeroImage && typeof parsedHeroImage === "object") {
      const heroUrl =
        typeof parsedHeroImage.link === "string"
          ? parsedHeroImage.link.trim()
          : "";

      sequence.heroImage = {
        enabled: heroUrl !== "",
        url: heroUrl || null,
        link: heroLink || null,
      };
    }
    sequence.editor = {
      font: ["Arial", "Roboto", "Verdana"].includes(parsedEditor.font)
        ? parsedEditor.font
        : "Arial",

      fontSize: ["12px", "14px", "16px", "18px", "20px"].includes(
        parsedEditor.fontSize,
      )
        ? parsedEditor.fontSize
        : "16px",

      textColor: ["Black", "Red", "Blue", "Green"].includes(
        parsedEditor.textColor,
      )
        ? parsedEditor.textColor
        : "Black",

      bold: toBoolean(parsedEditor.bold, false),

      italic: toBoolean(parsedEditor.italic, false),

      underline: toBoolean(parsedEditor.underline, false),
    };

    if (parsedAttachment && typeof parsedAttachment === "object") {
      const attachmentUrl =
        typeof parsedAttachment.url.trim() === "string"
          ? parsedAttachment.url.trim()
          : "";

      sequence.attachment = {
        enabled: attachmentUrl !== "",
        name: parsedAttachment.name?.toString().trim() || null,
        url: attachmentUrl || null,
        mimeType: parsedAttachment.mimeType?.toString().trim() || null,
        size: Number(parsedAttachment.size || 0),
      };
    }

    let whatsappUrl = "";

    if (typeof parsedActionLinks.whatsapp === "string") {
      whatsappUrl = parsedActionLinks.whatsapp.trim();
    } else if (typeof parsedActionLinks.whatsapp?.url === "string") {
      whatsappUrl = parsedActionLinks.whatsapp.url.trim();
    }

    const ctaText = parsedActionLinks.cta?.text?.toString().trim() || "";

    const ctaUrl = parsedActionLinks.cta?.url?.toString().trim() || "";

    sequence.actionLinks = {
      whatsapp: {
        enabled: whatsappUrl !== "",
        url: whatsappUrl || null,
      },

      cta: {
        enabled: ctaText !== "" && ctaUrl !== "",
        text: ctaText || null,
        url: ctaUrl || null,
      },
    };

    sequence.tracking.enabled = toBoolean(parsedTracking.enabled, true);

    await sequence.save();

    return res.status(200).json({
      success: true,
      message: "Sequence updated successfully",
      data: sequence,
    });
  } catch (error) {
    console.error("Error while updating sequence : ", error);

    if (error.name === "CastError") {
      return res.status(400).json({
        success: false,
        message: "Invalid Sequence ID",
      });
    }

    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "Another Sequence with this stepand varient already exist",
      });
    }
    return res.status(500).json({
      success: false,
      message: "Unable to update Sequence",
      error: error.message,
    });
  }
};
