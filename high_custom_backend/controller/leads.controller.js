const LEADS_COLLECTION = require("../model/leads.model");
const USER_COLLECTION = require("../model/user.model");
// ============================================================
// CREATE LEAD
// ============================================================

exports.createLead = async (req, res) => {
  try {
    // ========================================================
    // GET LOGGED-IN USER
    // ========================================================

    const userId = req.user?.id || req.user?._id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required.",
      });
    }

    // ========================================================
    // GET REQUEST DATA
    // ========================================================

    const { firstName, lastName, email, company, type, tracking } = req.body;

    // ========================================================
    // VALIDATE EMAIL
    // ========================================================

    if (!email || !email.trim()) {
      return res.status(400).json({
        success: false,
        message: "Please enter an email.",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    // ========================================================
    // VALIDATE EMAIL FORMAT
    // ========================================================

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(normalizedEmail)) {
      return res.status(400).json({
        success: false,
        message: "Please enter a valid email address.",
      });
    }

    // ========================================================
    // CHECK EXISTING EMAIL FOR THIS USER
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
    // VALIDATE TYPE
    // ========================================================

    const leadType = type === "WhatsApp" ? "WhatsApp" : "Email";

    // ========================================================
    // CREATE LEAD
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

        email: newLead.email,

        firstName: newLead.firstName,

        lastName: newLead.lastName,

        company: newLead.company,

        type: newLead.type,

        tracking: newLead.tracking,

        addedDate: newLead.createdAt,
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
    // ========================================================
    // GET LOGGED-IN USER
    // ========================================================

    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required.",
      });
    }

    // ========================================================
    // GET LEAD ID
    // ========================================================

    const { leadId } = req.params;

    if (!leadId) {
      return res.status(400).json({
        success: false,
        message: "Lead ID is required.",
      });
    }

    // ========================================================
    // GET REQUEST DATA
    // ========================================================

    const { firstName, lastName, email, company, type, tracking } = req.body;

    // ========================================================
    // FIND EXISTING LEAD
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
    // NORMALIZE DATA
    // ========================================================

    const newFirstName = firstName?.trim() || "";

    const newLastName = lastName?.trim() || "";

    const newEmail = email?.trim().toLowerCase() || "";

    const newCompany = company?.trim() || "";

    const newType = type === "WhatsApp" ? "WhatsApp" : "Email";

    const newTracking = tracking !== false;

    // ========================================================
    // VALIDATE EMAIL
    // ========================================================

    if (!newEmail) {
      return res.status(400).json({
        success: false,
        message: "Please enter an email.",
      });
    }

    // ========================================================
    // VALIDATE EMAIL FORMAT
    // ========================================================

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(newEmail)) {
      return res.status(400).json({
        success: false,
        message: "Please enter a valid email address.",
      });
    }

    // ========================================================
    // CHECK WHETHER ANYTHING CHANGED
    // ========================================================

    const noChanges =
      existingLead.firstName === newFirstName &&
      existingLead.lastName === newLastName &&
      existingLead.email === newEmail &&
      existingLead.company === newCompany &&
      existingLead.type === newType &&
      existingLead.tracking === newTracking;

    // ========================================================
    // SAME OLD DETAILS
    // ========================================================

    if (noChanges) {
      return res.status(400).json({
        success: false,
        changed: false,
        message: "Please enter details different from the old details.",
      });
    }

    // ========================================================
    // CHECK WHETHER EMAIL BELONGS TO ANOTHER LEAD
    // ========================================================

    if (newEmail !== existingLead.email) {
      const duplicateLead = await LEADS_COLLECTION.findOne({
        userId: userId,
        email: newEmail,
        id: { $ne: leadId },
      });

      if (duplicateLead) {
        return res.status(400).json({
          success: false,
          message: "Email already exists in your leads.",
        });
      }
    }

    // ========================================================
    // UPDATE LEAD
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

        email: existingLead.email,

        firstName: existingLead.firstName,

        lastName: existingLead.lastName,

        company: existingLead.company,

        type: existingLead.type,

        tracking: existingLead.tracking,

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
