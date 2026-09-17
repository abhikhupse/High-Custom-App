const LEADS_COLLECTION = require("../model/leads.model");
const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");
const INTEREST_DETAILS = require("../model/lead_interest_details.model");
const XLSX = require("xlsx");

const { predictLeadFromEmail } = require("../utils/emailLeadPredictor");
const { processSequencesForUser } = require("../jobs/sequence.job");

// ============================================================
// GET LOGGED-IN USER ID
// ============================================================

const getUserId = (req) => {
  return req.user?.id || req.user?._id;
};

// ============================================================
// INTERESTED LEADS — CURRENT ADMIN WORKSPACE ONLY
// ============================================================
exports.getMyInterestedLeads = async (req, res) => {
  try {
    const userId = getUserId(req);
    if (!userId)
      return res.status(401).json({ success: false, message: "User authentication required." });

    const page = Math.max(Number.parseInt(req.query.page, 10) || 1, 1);
    const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 10, 1), 100);
    const query = { userId };
    const startDate = req.query.startDate ? new Date(req.query.startDate) : null;
    const endDate = req.query.endDate ? new Date(req.query.endDate) : null;
    if (startDate && !Number.isNaN(startDate.getTime())) {
      startDate.setHours(0, 0, 0, 0);
      query.submittedAt = { ...(query.submittedAt || {}), $gte: startDate };
    }
    if (endDate && !Number.isNaN(endDate.getTime())) {
      endDate.setHours(23, 59, 59, 999);
      query.submittedAt = { ...(query.submittedAt || {}), $lte: endDate };
    }

    const leadQuery = { userId };
    if (req.query.businessType)
      leadQuery.businessType = String(req.query.businessType).trim();
    if (req.query.search && String(req.query.search).trim()) {
      const expression = new RegExp(
        String(req.query.search).trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&"),
        "i",
      );
      leadQuery.$or = [
        { firstName: expression }, { lastName: expression }, { email: expression }, { company: expression },
      ];
      query.$or = [
        { name: expression }, { mobileNumber: expression }, { companyName: expression },
      ];
    }
    if (req.query.businessType || req.query.search) {
      const leadIds = await LEADS_COLLECTION.find(leadQuery).distinct("_id");
      if (query.$or) {
        // A free-text match may come from the response form itself or from
        // its linked lead record, mirroring the company-wide Admin search.
        query.$or.push({ leadId: { $in: leadIds } });
      } else query.leadId = { $in: leadIds };
    }

    const [details, total, businessTypes] = await Promise.all([
      INTEREST_DETAILS.find(query)
        .populate("leadId", "firstName lastName email company businessType")
        .populate("sequenceId", "subject step variant")
        .sort({ submittedAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
      INTEREST_DETAILS.countDocuments(query),
      LEADS_COLLECTION.distinct("businessType", { userId, businessType: { $nin: [null, ""] } }),
    ]);
    return res.json({
      success: true,
      details,
      pagination: { page, limit, total, totalPages: Math.max(Math.ceil(total / limit), 1) },
      filterOptions: { businessTypes: businessTypes.sort() },
    });
  } catch (error) {
    console.error("GET MY INTERESTED LEADS ERROR:", error);
    return res.status(500).json({ success: false, message: "Unable to load interested leads." });
  }
};

exports.deleteMyInterestedLead = async (req, res) => {
  try {
    const userId = getUserId(req);
    const removed = await INTEREST_DETAILS.findOneAndDelete({ _id: req.params.interestId, userId });
    if (!removed)
      return res.status(404).json({ success: false, message: "Interested lead record not found." });
    return res.json({ success: true, message: "Interested lead record deleted." });
  } catch (error) {
    return res.status(400).json({ success: false, message: "Unable to delete interested lead record." });
  }
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

    const query = {
      userId,
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

      end.setHours(23, 59, 59, 999);

      query.createdAt = {
        ...query.createdAt,
        $lte: end,
      };
    }

    // ========================================================
    // FIND LEADS
    // ========================================================

    const leads = await LEADS_COLLECTION.find(query)
      .sort({
        createdAt: -1,
      })
      .lean();

    // ========================================================
    // GET LEAD IDS
    // ========================================================

    const leadIds = leads.map((lead) => lead._id);

    // ========================================================
    // GET DELIVERY DATA
    // ========================================================

    const deliveries = leadIds.length
      ? await SEQUENCE_DELIVERY.find({
          userId,
          leadId: {
            $in: leadIds,
          },
        })
          .sort({
            createdAt: -1,
          })
          .lean()
      : [];

    // ========================================================
    // TRACKING STATUS
    // ========================================================

    const trackingByLead = new Map();
    const trackingRank = {
      Pending: 10,
      Failed: 20,
      Sent: 30,
      Opened: 40,
      Clicked: 50,
      Replied: 60,
      Interested: 70,
      "Not Interested": 70,
    };

    for (const delivery of deliveries) {
      const leadId = delivery.leadId.toString();
      let status = "Pending";
      const response = String(delivery.response || "")
        .trim()
        .toLowerCase();
      const deliveryStatus = String(delivery.status || "")
        .trim()
        .toLowerCase();

      // Normalize older and newer delivery values so the Leads list shows
      // the latest activity instead of incorrectly falling back to Pending.
      if (["interested", "positive"].includes(response)) {
        status = "Interested";
      } else if (
        ["notinterested", "not-interested", "not interested", "negative"].includes(
          response,
        )
      ) {
        status = "Not Interested";
      } else if (delivery.repliedAt) {
        status = "Replied";
      } else if (
        delivery.clickedAt ||
        delivery.clickCount > 0 ||
        delivery.clicked === true
      ) {
        status = "Clicked";
      } else if (delivery.openedAt) {
        status = "Opened";
      } else if (["sent", "success", "delivered"].includes(deliveryStatus)) {
        status = "Sent";
      } else if (deliveryStatus === "failed") {
        status = "Failed";
      }

      const existingStatus = trackingByLead.get(leadId);

      if (
        !existingStatus ||
        trackingRank[status] > trackingRank[existingStatus]
      ) {
        trackingByLead.set(leadId, status);
      }
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

        businessType: lead.businessType || "",

        tracking: lead.tracking !== false,

        trackingStatus:
          String(lead.responseStatus || "").toLowerCase() === "interested"
            ? "Interested"
            : ["notinterested", "not-interested", "not interested"].includes(
                  String(lead.responseStatus || "")
                    .trim()
                    .toLowerCase(),
                )
              ? "Not Interested"
              : trackingByLead.get(lead._id.toString()) ||
          (lead.tracking === false ? "Skip" : "Pending"),

        responseStatus: lead.responseStatus || null,
        respondedAt: lead.respondedAt || null,

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

    const {
      firstName,
      lastName,
      email,
      company,
      type,
      businessType,
      tracking,
      scheduledAt,
    } = req.body;

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

    const normalizedBusinessType =
      typeof businessType === "string" ? businessType.trim() : "";

    if (!normalizedBusinessType) {
      return res.status(400).json({
        success: false,
        message: "Please select a business type.",
      });
    }

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
      userId,
      email: normalizedEmail,
    });

    if (existingLead) {
      return res.status(400).json({
        success: false,
        message: "Email already exists in your leads.",
      });
    }

    // ========================================================
    // ORIGINAL DATA
    // ========================================================

    let newFirstName = firstName?.trim() || "";
    let newLastName = lastName?.trim() || "";
    let newCompany = company?.trim() || "";

    // ========================================================
    // AUTOMATIC PREDICTION
    //
    // IMPORTANT:
    // Prediction only happens when the corresponding field
    // is empty.
    // ========================================================

    if (!newFirstName && !newLastName && !newCompany) {
      const prediction = predictLeadFromEmail(normalizedEmail);

      newFirstName = prediction.firstName || "";
      newLastName = prediction.lastName || "";
      newCompany = prediction.company || "";
    }

    // ========================================================
    // TYPE
    // ========================================================

    const leadType = type === "WhatsApp" ? "WhatsApp" : "Email";

    let normalizedScheduledAt = null;
    if (scheduledAt) {
      normalizedScheduledAt = new Date(scheduledAt);
      if (Number.isNaN(normalizedScheduledAt.getTime())) {
        return res.status(400).json({
          success: false,
          message: "Please select a valid schedule date and time.",
        });
      }
    }

    // ========================================================
    // CREATE LEAD
    // ========================================================

    const newLead = await LEADS_COLLECTION.create({
      userId,

      firstName: newFirstName,
      lastName: newLastName,

      email: normalizedEmail,

      company: newCompany,

      type: leadType,

      businessType: normalizedBusinessType,

      tracking: tracking !== false,

      scheduledAt: normalizedScheduledAt,
    });

    // Process active sequences immediately for a newly added email lead.
    // This runs after the response cycle begins so lead creation is not blocked.
    if (
      newLead.type === "Email" &&
      newLead.tracking &&
      (!newLead.scheduledAt || newLead.scheduledAt <= new Date())
    ) {
      setImmediate(async () => {
        try {
          const result = await processSequencesForUser(userId);

          console.log("Sequences processed after lead creation:", {
            leadId: newLead._id,
            email: newLead.email,
            result,
          });
        } catch (emailError) {
          console.error(
            "Failed to process sequences after creating lead:",
            emailError,
          );
        }
      });
    }

    // ========================================================
    // RESPONSE
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

        businessType: newLead.businessType,

        tracking: newLead.tracking,

        trackingStatus: newLead.tracking ? "Pending" : "Skip",

        addedDate: newLead.createdAt,
        updatedDate: newLead.updatedAt,
      },
    });
  } catch (error) {
    console.error("Error while adding a lead:", error);

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: "Email already exists in your leads.",
      });
    }

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

    const { leadId } = req.params;

    if (!leadId) {
      return res.status(400).json({
        success: false,
        message: "Lead ID is required.",
      });
    }

    const {
      firstName,
      lastName,
      email,
      company,
      type,
      businessType,
      tracking,
    } = req.body;

    // ========================================================
    // FIND LEAD
    // ========================================================

    const existingLead = await LEADS_COLLECTION.findOne({
      _id: leadId,
      userId,
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

    const newBusinessType =
      typeof businessType === "string"
        ? businessType.trim()
        : existingLead.businessType || "";

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
      existingLead.businessType === newBusinessType &&
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
        userId,
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
    existingLead.businessType = newBusinessType;
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

        businessType: existingLead.businessType,

        tracking: existingLead.tracking,

        trackingStatus: existingLead.tracking ? "Pending" : "Skip",

        addedDate: existingLead.createdAt,
        updatedDate: existingLead.updatedAt,
      },
    });
  } catch (error) {
    console.error("Error while editing lead:", error);

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: "Email already exists in your leads.",
      });
    }

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

    const { leadId } = req.params;

    if (!leadId) {
      return res.status(400).json({
        success: false,
        message: "Lead ID is required.",
      });
    }

    const lead = await LEADS_COLLECTION.findOne({
      _id: leadId,
      userId,
    });

    if (!lead) {
      return res.status(404).json({
        success: false,
        message: "Lead not found.",
      });
    }

    await LEADS_COLLECTION.deleteOne({
      _id: leadId,
      userId,
    });

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

// ============================================================
// BULK IMPORT LEADS FROM EXCEL
// ============================================================

exports.importLeadsFromExcel = async (req, res) => {
  try {
    const userId = getUserId(req);

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required.",
      });
    }

    // ========================================================
    // FILE CHECK
    // ========================================================

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "Please upload an Excel file.",
      });
    }

    // ========================================================
    // READ EXCEL
    // ========================================================

    const workbook = XLSX.read(req.file.buffer, {
      type: "buffer",
    });

    const sheetName = workbook.SheetNames[0];

    if (!sheetName) {
      return res.status(400).json({
        success: false,
        message: "Excel file does not contain a worksheet.",
      });
    }

    const worksheet = workbook.Sheets[sheetName];

    const rows = XLSX.utils.sheet_to_json(worksheet, {
      defval: "",
      raw: false,
    });

    if (!rows.length) {
      return res.status(400).json({
        success: false,
        message: "Excel file is empty.",
      });
    }

    // ========================================================
    // HELPER
    // ========================================================

    const getValue = (row, names) => {
      for (const name of names) {
        if (Object.prototype.hasOwnProperty.call(row, name)) {
          return row[name];
        }
      }

      return "";
    };

    // ========================================================
    // EMAIL VALIDATION
    // ========================================================

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    // ========================================================
    // GET EXISTING EMAILS
    // ========================================================

    const existingLeads = await LEADS_COLLECTION.find(
      {
        userId,
      },
      {
        email: 1,
      },
    ).lean();

    const existingEmails = new Set(
      existingLeads
        .map((lead) =>
          String(lead.email || "")
            .trim()
            .toLowerCase(),
        )
        .filter(Boolean),
    );

    // ========================================================
    // PROCESS ROWS
    // ========================================================

    const validLeads = [];

    const errors = [];

    const importedEmails = new Set();

    rows.forEach((row, index) => {
      const excelRowNumber = index + 2;

      // ======================================================
      // GET EXCEL VALUES
      // ======================================================

      let firstName = String(
        getValue(row, ["First Name", "firstName", "FirstName", "FIRST NAME"]),
      ).trim();

      let lastName = String(
        getValue(row, ["Last Name", "lastName", "LastName", "LAST NAME"]),
      ).trim();

      const email = String(getValue(row, ["Email", "email", "EMAIL"]))
        .trim()
        .toLowerCase();

      let company = String(
        getValue(row, ["Company", "company", "COMPANY"]),
      ).trim();

      const typeValue = String(getValue(row, ["Type", "type", "TYPE"]))
        .trim()
        .toLowerCase();

      const businessType = String(
        getValue(row, [
          "Business Type",
          "businessType",
          "BusinessType",
          "BUSINESS TYPE",
          "BUSINESSTYPE",
        ]),
      ).trim();

      const trackingValue = String(
        getValue(row, ["Tracking", "tracking", "TRACKING"]),
      )
        .trim()
        .toLowerCase();

      // ======================================================
      // EMAIL REQUIRED
      // ======================================================

      if (!email) {
        errors.push({
          row: excelRowNumber,
          email: "",
          message: "Email is required.",
        });

        return;
      }

      // ======================================================
      // EMAIL FORMAT
      // ======================================================

      if (!emailRegex.test(email)) {
        errors.push({
          row: excelRowNumber,
          email,
          message: "Invalid email address.",
        });

        return;
      }

      // ======================================================
      // DATABASE DUPLICATE
      // ======================================================

      if (existingEmails.has(email)) {
        errors.push({
          row: excelRowNumber,
          email,
          message: "Email already exists in your leads.",
        });

        return;
      }

      // ======================================================
      // EXCEL DUPLICATE
      // ======================================================

      if (importedEmails.has(email)) {
        errors.push({
          row: excelRowNumber,
          email,
          message: "Duplicate email found in Excel file.",
        });

        return;
      }

      importedEmails.add(email);

      // ======================================================
      // AUTOMATIC EMAIL PREDICTION
      // ======================================================
      //
      // VERY IMPORTANT:
      //
      // Prediction is performed ONLY when the Excel row
      // does not already contain name/company information.
      //
      // Existing Excel data is NEVER overwritten.
      //
      // ======================================================

      if (!firstName && !lastName && !company) {
        const prediction = predictLeadFromEmail(email);

        firstName = prediction.firstName || "";

        lastName = prediction.lastName || "";

        company = prediction.company || "";
      }

      // ======================================================
      // TYPE
      // ======================================================

      const type = typeValue === "whatsapp" ? "WhatsApp" : "Email";

      // ======================================================
      // CREATE LEAD OBJECT
      // ======================================================

      validLeads.push({
        userId,

        firstName,
        lastName,

        email,

        company,

        type,

        businessType,

        tracking: !["false", "no", "0", "disabled"].includes(
          trackingValue,
        ),
      });
    });

    // ========================================================
    // INSERT INTO DATABASE
    // ========================================================

    let insertedLeads = [];

    if (validLeads.length > 0) {
      insertedLeads = await LEADS_COLLECTION.insertMany(validLeads, {
        ordered: false,
      });
    }

    // Start active sequences immediately for newly imported leads. The HTTP
    // response is not blocked while Gmail processes the campaign.
    if (insertedLeads.length > 0) {
      setImmediate(async () => {
        try {
          const result = await processSequencesForUser(userId);

          console.log("Sequences processed after bulk lead import:", {
            imported: insertedLeads.length,
            result,
          });
        } catch (sequenceError) {
          console.error(
            "Failed to process sequences after bulk lead import:",
            sequenceError,
          );
        }
      });
    }

    // ========================================================
    // RESPONSE
    // ========================================================

    return res.status(200).json({
      success: true,

      message: "Excel leads import completed.",

      totalRows: rows.length,

      imported: insertedLeads.length,

      skipped: errors.length,

      errors,
    });
  } catch (error) {
    console.error("Error importing leads from Excel:", error);

    return res.status(500).json({
      success: false,

      message: "Unable to import leads from Excel.",

      error: error.message,
    });
  }
};

// ============================================================
// EXPORT LEADS TO EXCEL
// ============================================================

exports.exportLeadsToExcel = async (req, res) => {
  try {
    const userId = getUserId(req);

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required.",
      });
    }

    // ========================================================
    // GET USER LEADS
    // ========================================================

    const leads = await LEADS_COLLECTION.find({
      userId,
    })
      .sort({
        createdAt: -1,
      })
      .lean();

    // ========================================================
    // EXCEL ROWS
    // ========================================================

    const rows = leads.map((lead) => ({
      "First Name": lead.firstName || "",
      "Last Name": lead.lastName || "",
      Email: lead.email || "",
      Company: lead.company || "",
      Type: lead.type || "Email",
    }));

    // ========================================================
    // CREATE WORKSHEET
    // ========================================================

    const worksheet = XLSX.utils.json_to_sheet(rows);

    // ========================================================
    // COLUMN WIDTHS
    // ========================================================

    worksheet["!cols"] = [
      {
        wch: 18,
      },
      {
        wch: 18,
      },
      {
        wch: 35,
      },
      {
        wch: 30,
      },
      {
        wch: 15,
      },
    ];

    // ========================================================
    // CREATE WORKBOOK
    // ========================================================

    const workbook = XLSX.utils.book_new();

    XLSX.utils.book_append_sheet(workbook, worksheet, "Leads");

    // ========================================================
    // WRITE BUFFER
    // ========================================================

    const buffer = XLSX.write(workbook, {
      type: "buffer",
      bookType: "xlsx",
    });

    // ========================================================
    // RESPONSE HEADERS
    // ========================================================

    res.setHeader(
      "Content-Type",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    );

    res.setHeader("Content-Disposition", 'attachment; filename="leads.xlsx"');

    return res.status(200).send(buffer);
  } catch (error) {
    console.error("Error exporting leads to Excel:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to download leads Excel file.",
      error: error.message,
    });
  }
};
