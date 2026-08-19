const LEADS_COLLECTION = require("../model/leads.model");
const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");

// ============================================================
// GET LOGGED-IN USER ID
// ============================================================

const getUserId = (req) => {
  return req.user?.id || req.user?._id;
};

// ============================================================
// GET ALL LEADS
// ============================================================

exports.getLeads = async (req, res) => {
  try {
    const userId = getUserId(req);

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required.",
      });
    }

    // ========================================================
    // DATE FILTER
    // ========================================================

    const { startDate, endDate } = req.query;

    // ========================================================
    // BUILD QUERY
    // ========================================================

    const query = {
      userId: userId,
    };

    // ========================================================
    // START DATE
    // ========================================================

    if (startDate) {
      const start = new Date(startDate);

      if (isNaN(start.getTime())) {
        return res.status(400).json({
          success: false,
          message: "Invalid startDate.",
        });
      }

      // Start of selected day
      start.setHours(0, 0, 0, 0);

      query.createdAt = {
        ...query.createdAt,
        $gte: start,
      };
    }

    // ========================================================
    // END DATE
    // ========================================================

    if (endDate) {
      const end = new Date(endDate);

      if (isNaN(end.getTime())) {
        return res.status(400).json({
          success: false,
          message: "Invalid endDate.",
        });
      }

      // End of selected day
      end.setHours(23, 59, 59, 999);

      query.createdAt = {
        ...query.createdAt,
        $lte: end,
      };
    }

    // ========================================================
    // FIND USER LEADS
    // ========================================================

    const leads = await LEADS_COLLECTION.find(query)
      .sort({
        createdAt: -1,
      })
      .lean();

    const leadIds = leads.map((lead) => lead._id);
    const deliveries = leadIds.length
      ? await SEQUENCE_DELIVERY.find({
          userId,
          leadId: { $in: leadIds },
        })
          .sort({ createdAt: -1 })
          .lean()
      : [];

    const trackingByLead = new Map();

    for (const delivery of deliveries) {
      const leadId = delivery.leadId.toString();

      if (trackingByLead.has(leadId)) {
        continue;
      }

      trackingByLead.set(
        leadId,
        delivery.openedAt
          ? "Seen"
          : delivery.status === "failed"
            ? "Failed"
            : delivery.status === "pending"
              ? "Pending"
              : "Sent",
      );
    }

    // ========================================================
    // RESPONSE
    // ========================================================

    return res.status(200).json({
      success: true,

      message: "Leads fetched successfully.",

      leads: leads.map((lead) => ({
        id: lead._id,

        _id: lead._id,

        email: lead.email || "",

        firstName: lead.firstName || "",

        lastName: lead.lastName || "",

        company: lead.company || "",

        type: lead.type || "Email",

        tracking: lead.tracking !== false,

        trackingStatus:
          lead.tracking === false
            ? "Skip"
            : trackingByLead.get(lead._id.toString()) || "Pending",

        addedDate: lead.createdAt,

        updatedDate: lead.updatedAt,
      })),
    });
  } catch (error) {
    console.error("Error while fetching leads:", error);

    return res.status(500).json({
      success: false,
      message: "Internal Server Error.",
      error: error.message,
    });
  }
};

// ============================================================
// CREATE LEAD
// ============================================================

exports.createLead = async (req, res) => {
  try {
    const userId = getUserId(req);

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required.",
      });
    }

    // ========================================================
    // REQUEST DATA
    // ========================================================

    const { firstName, lastName, email, company, type, tracking } = req.body;

    // ========================================================
    // EMAIL REQUIRED
    // ========================================================

    if (!email || !email.trim()) {
      return res.status(400).json({
        success: false,
        message: "Please enter an email.",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    // ========================================================
    // EMAIL VALIDATION
    // ========================================================

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(normalizedEmail)) {
      return res.status(400).json({
        success: false,
        message: "Please enter a valid email address.",
      });
    }

    // ========================================================
    // DUPLICATE CHECK
    // ========================================================

    const existingLead = await LEADS_COLLECTION.findOne({
      userId: userId,
      email: normalizedEmail,
    });

    if (existingLead) {
      return res.status(400).json({
        success: false,
        message: "Email already exists in your leads.",
      });
    }

    // ========================================================
    // TYPE
    // ========================================================

    const leadType = type === "WhatsApp" ? "WhatsApp" : "Email";

    // ========================================================
    // CREATE
    // ========================================================

    const newLead = await LEADS_COLLECTION.create({
      userId: userId,

      firstName: firstName?.trim() || "",

      lastName: lastName?.trim() || "",

      email: normalizedEmail,

      company: company?.trim() || "",

      type: leadType,

      tracking: tracking !== false,
    });

    // ========================================================
    // SUCCESS
    // ========================================================

    return res.status(201).json({
      success: true,

      message: "Lead created successfully.",

      lead: {
        id: newLead._id,

        _id: newLead._id,

        email: newLead.email,

        firstName: newLead.firstName,

        lastName: newLead.lastName,

        company: newLead.company,

        type: newLead.type,

        tracking: newLead.tracking,

        trackingStatus: newLead.tracking ? "Pending" : "Skip",

        addedDate: newLead.createdAt,

        updatedDate: newLead.updatedAt,
      },
    });
  } catch (error) {
    console.error("Error while adding a lead:", error);

    // ========================================================
    // DUPLICATE KEY
    // ========================================================

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: "Email already exists in your leads.",
      });
    }

    // ========================================================
    // SERVER ERROR
    // ========================================================

    return res.status(500).json({
      success: false,
      message: "Internal Server Error.",
      error: error.message,
    });
  }
};

// ============================================================
// EDIT LEAD
// ============================================================

exports.editLead = async (req, res) => {
  try {
    const userId = getUserId(req);

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required.",
      });
    }

    // ========================================================
    // LEAD ID
    // ========================================================

    const { leadId } = req.params;

    if (!leadId) {
      return res.status(400).json({
        success: false,
        message: "Lead ID is required.",
      });
    }

    // ========================================================
    // REQUEST DATA
    // ========================================================

    const { firstName, lastName, email, company, type, tracking } = req.body;

    // ========================================================
    // FIND LEAD
    // ========================================================

    const existingLead = await LEADS_COLLECTION.findOne({
      _id: leadId,
      userId: userId,
    });

    if (!existingLead) {
      return res.status(404).json({
        success: false,
        message: "Lead not found.",
      });
    }

    // ========================================================
    // NORMALIZE
    // ========================================================

    const newFirstName = firstName?.trim() || "";

    const newLastName = lastName?.trim() || "";

    const newEmail = email?.trim().toLowerCase() || "";

    const newCompany = company?.trim() || "";

    const newType = type === "WhatsApp" ? "WhatsApp" : "Email";

    const newTracking = tracking !== false;

    // ========================================================
    // EMAIL REQUIRED
    // ========================================================

    if (!newEmail) {
      return res.status(400).json({
        success: false,
        message: "Please enter an email.",
      });
    }

    // ========================================================
    // EMAIL FORMAT
    // ========================================================

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(newEmail)) {
      return res.status(400).json({
        success: false,
        message: "Please enter a valid email address.",
      });
    }

    // ========================================================
    // CHECK CHANGES
    // ========================================================

    const noChanges =
      existingLead.firstName === newFirstName &&
      existingLead.lastName === newLastName &&
      existingLead.email === newEmail &&
      existingLead.company === newCompany &&
      existingLead.type === newType &&
      existingLead.tracking === newTracking;

    if (noChanges) {
      return res.status(400).json({
        success: false,
        changed: false,
        message: "Please enter details different from the old details.",
      });
    }

    // ========================================================
    // DUPLICATE EMAIL
    // ========================================================

    if (newEmail !== existingLead.email) {
      const duplicateLead = await LEADS_COLLECTION.findOne({
        userId: userId,

        email: newEmail,

        _id: {
          $ne: leadId,
        },
      });

      if (duplicateLead) {
        return res.status(400).json({
          success: false,
          message: "Email already exists in your leads.",
        });
      }
    }

    // ========================================================
    // UPDATE
    // ========================================================

    existingLead.firstName = newFirstName;

    existingLead.lastName = newLastName;

    existingLead.email = newEmail;

    existingLead.company = newCompany;

    existingLead.type = newType;

    existingLead.tracking = newTracking;

    await existingLead.save();

    // ========================================================
    // SUCCESS
    // ========================================================

    return res.status(200).json({
      success: true,

      changed: true,

      message: "Lead updated successfully.",

      lead: {
        id: existingLead._id,

        _id: existingLead._id,

        email: existingLead.email,

        firstName: existingLead.firstName,

        lastName: existingLead.lastName,

        company: existingLead.company,

        type: existingLead.type,

        tracking: existingLead.tracking,

        trackingStatus: existingLead.tracking ? "Sent" : "Skip",

        addedDate: existingLead.createdAt,

        updatedDate: existingLead.updatedAt,
      },
    });
  } catch (error) {
    console.error("Error while editing lead:", error);

    // ========================================================
    // DUPLICATE KEY
    // ========================================================

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: "Email already exists in your leads.",
      });
    }

    // ========================================================
    // SERVER ERROR
    // ========================================================

    return res.status(500).json({
      success: false,
      message: "Internal Server Error.",
      error: error.message,
    });
  }
};

// ============================================================
// DELETE LEAD
// ============================================================

exports.deleteLead = async (req, res) => {
  try {
    const userId = getUserId(req);

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required.",
      });
    }

    // ========================================================
    // LEAD ID
    // ========================================================

    const { leadId } = req.params;

    if (!leadId) {
      return res.status(400).json({
        success: false,
        message: "Lead ID is required.",
      });
    }

    // ========================================================
    // FIND LEAD
    // ========================================================

    const lead = await LEADS_COLLECTION.findOne({
      _id: leadId,
      userId: userId,
    });

    if (!lead) {
      return res.status(404).json({
        success: false,
        message: "Lead not found.",
      });
    }

    // ========================================================
    // DELETE
    // ========================================================

    await LEADS_COLLECTION.deleteOne({
      _id: leadId,
      userId: userId,
    });

    // ========================================================
    // SUCCESS
    // ========================================================

    return res.status(200).json({
      success: true,

      message: "Lead deleted successfully.",

      leadId: lead._id,
    });
  } catch (error) {
    console.error("Error while deleting lead:", error);

    return res.status(500).json({
      success: false,
      message: "Internal Server Error.",
      error: error.message,
    });
  }
};
