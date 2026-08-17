const SEQUENCE_COLLECTION = require("../model/sequence.model");
const crypto = require("crypto");
const { query } = require("../routes/sequence.routes");

// CREATE SEQUENCE

exports.createSequence = async (req, res) => {
  try {
    // ==========================================================
    // GET AUTHENTICATED USER
    // ==========================================================

    // Get userId from authenticated user instead of req.body.
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

    /*
      Multer upload.fields() creates req.files like:

      req.files = {
        brandLogo: [file],
        heroImage: [file],
        attachment: [file]
      }
    */

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

    // Convert step to number
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

      // ========================================================
      // BASIC INFORMATION
      // ========================================================

      step: stepNumber,

      gapDays: gapDaysNumber,

      variant: formattedVariant,

      type,

      // ========================================================
      // SUBJECT
      // ========================================================

      subject: formattedSubject,

      // ========================================================
      // BRAND IDENTITY
      // ========================================================

      brand: {
        logoUrl: logoUrl || brand?.logoUrl || null,

        logoPosition: brand?.logoPosition || "Center",
      },

      // ========================================================
      // HERO IMAGE
      // ========================================================

      heroImage: {
        url: heroUrl || heroImage?.url || null,

        link: heroImage?.link || null,
      },

      // ========================================================
      // EMAIL CONTENT
      // ========================================================

      content,

      // ========================================================
      // EDITOR
      // ========================================================

      editor: {
        font: editor?.font || "Arial",

        fontSize: editor?.fontSize || "16px",

        textColor: editor?.textColor || "Black",

        bold: editor?.bold ?? false,

        italic: editor?.italic ?? false,

        underline: editor?.underline ?? false,
      },

      // ========================================================
      // ATTACHMENT
      // ========================================================

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

      // ========================================================
      // ACTION LINKS
      // ========================================================

      actionLinks: {
        whatsapp: actionLinks?.whatsapp || null,
      },

      // ========================================================
      // TRACKING
      // ========================================================

      tracking: trackingData,

      // ========================================================
      // STATUS
      // ========================================================

      status: status || "draft",

      // ========================================================
      // SCHEDULING
      // ========================================================

      scheduledAt: scheduledAt || null,

      // ========================================================
      // STATISTICS
      // ========================================================

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

    // ==========================================================
    // SUCCESS RESPONSE
    // ==========================================================

    return res.status(201).json({
      success: true,

      message: "Sequence Created Successfully",

      data: sequence,
    });
  } catch (error) {
    // ==========================================================
    // ERROR LOG
    // ==========================================================

    console.error("Error while creating Sequence:", error);

    // ==========================================================
    // MULTER FILE SIZE ERROR
    // ==========================================================

    if (error.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({
        success: false,
        message: "Uploaded file is too large",
      });
    }

    // ==========================================================
    // MULTER FILE COUNT ERROR
    // ==========================================================

    if (error.code === "LIMIT_FILE_COUNT") {
      return res.status(400).json({
        success: false,
        message: "Too many files uploaded",
      });
    }

    // ==========================================================
    // MULTER FIELD ERROR
    // ==========================================================

    if (error.code === "LIMIT_UNEXPECTED_FILE") {
      return res.status(400).json({
        success: false,
        message: "Unexpected file field",
      });
    }

    // ==========================================================
    // MULTER FILE TYPE / CUSTOM ERROR
    // ==========================================================

    /*
      This handles errors thrown from your
      upload.middleware.js fileFilter.
    */

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

    // ==========================================================
    // DUPLICATE KEY ERROR
    // ==========================================================

    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "A sequence with this step and variant already exists",
      });
    }

    // ==========================================================
    // MONGOOSE VALIDATION ERROR
    // ==========================================================

    if (error.name === "ValidationError") {
      const errors = Object.values(error.errors).map((err) => err.message);

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
    // GENERAL SERVER ERROR
    // ==========================================================

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

    // ============================================================
    // PAGINATION
    // ============================================================

    const page = Math.max(Number.parseInt(req.query.page, 10) || 1, 1);

    const limit = Math.min(
      Math.max(Number.parseInt(req.query.limit, 10) || 10, 1),
      100,
    );

    const skip = (page - 1) * limit;

    // ============================================================
    // SEARCH
    // ============================================================

    const search =
      typeof req.query.search === "string" ? req.query.search.trim() : "";

    const status =
      typeof req.query.status === "string" ? req.query.status.trim() : "";

    // ============================================================
    // QUERY
    // ============================================================

    const query = {
      userId: userId,
    };

    // ============================================================
    // SEARCH FILTER
    // ============================================================

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

    // ============================================================
    // STATUS FILTER
    // ============================================================

    if (status) {
      query.status = status;
    }

    // ============================================================
    // TOTAL COUNT
    // ============================================================

    const total = await SEQUENCE_COLLECTION.countDocuments(query);

    // ============================================================
    // FETCH DATA
    // ============================================================

    const sequences = await SEQUENCE_COLLECTION.find(query)
      .sort({
        step: 1,
        createdAt: -1,
      })
      .skip(skip)
      .limit(limit)
      .lean();

    // ============================================================
    // PAGINATION
    // ============================================================

    const totalPages = Math.ceil(total / limit);

    // ============================================================
    // RESPONSE
    // ============================================================

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
