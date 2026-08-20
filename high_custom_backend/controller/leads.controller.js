const LEADS_COLLECTION = require("../model/leads.model");
const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");
const XLSX = require("xlsx");

const { predictLeadFromEmail } = require("../utils/emailLeadPredictor");

// ============================================================
// GET LOGGED-IN USER ID
// ============================================================

const getUserId = (req) => {
  return req.user?.id || req.user?._id;
};

// ============================================================
// EMAIL VALIDATION
// ============================================================

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// ============================================================
// NORMALIZE TEXT
// ============================================================

const normalizeText = (value) => {
  if (value === null || value === undefined) {
    return "";
  }

  return String(value).trim();
};

// ============================================================
// GET VALUE FROM EXCEL ROW
// ============================================================

const getValue = (row, names) => {
  for (const name of names) {
    if (Object.prototype.hasOwnProperty.call(row, name)) {
      return row[name];
    }
  }

  return "";
};

// ============================================================
// NORMALIZE PREDICTOR RESULT
//
// This allows the controller to work with slightly different
// return formats from emailLeadPredictor.js.
//
// Supported examples:
//
// {
//   firstName: "John",
//   lastName: "Doe",
//   company: ""
// }
//
// or
//
// {
//   fullName: "John Doe",
//   company: ""
// }
//
// or
//
// {
//   firstName: "-",
//   lastName: "-",
//   company: ""
// }
// ============================================================

const normalizePrediction = (prediction) => {
  if (!prediction || typeof prediction !== "object") {
    return {
      firstName: "",
      lastName: "",
      company: "",
    };
  }

  let firstName = normalizeText(
    prediction.firstName || prediction.first_name || "",
  );

  let lastName = normalizeText(
    prediction.lastName || prediction.last_name || "",
  );

  let company = normalizeText(
    prediction.company ||
      prediction.companyName ||
      prediction.company_name ||
      "",
  );

  // ==========================================================
  // FULL NAME SUPPORT
  // ==========================================================

  const fullName = normalizeText(
    prediction.fullName || prediction.full_name || prediction.name || "",
  );

  if (!firstName && !lastName && fullName) {
    const parts = fullName
      .split(/\s+/)
      .map((part) => part.trim())
      .filter(Boolean);

    if (parts.length === 1) {
      firstName = parts[0];
    } else if (parts.length > 1) {
      firstName = parts[0];
      lastName = parts.slice(1).join(" ");
    }
  }

  return {
    firstName,
    lastName,
    company,
  };
};

// ============================================================
// PREDICT LEAD FROM EMAIL
//
// IMPORTANT:
// This function is used ONLY when Excel does not already
// contain first name and last name.
//
// It never replaces user-provided Excel data.
// ============================================================

const predictMissingLeadDetails = async (email) => {
  try {
    if (!email) {
      return {
        firstName: "",
        lastName: "",
        company: "",
      };
    }

    if (typeof predictLeadFromEmail !== "function") {
      console.warn(
        "predictLeadFromEmail is not available. Skipping prediction.",
      );

      return {
        firstName: "",
        lastName: "",
        company: "",
      };
    }

    const prediction = await predictLeadFromEmail(email);

    return normalizePrediction(prediction);
  } catch (error) {
    console.error(
      `Unable to predict lead details for ${email}:`,
      error.message,
    );

    // Prediction failure must NOT stop Excel import.
    return {
      firstName: "",
      lastName: "",
      company: "",
    };
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
    // FIND USER LEADS
    // ========================================================

    const leads = await LEADS_COLLECTION.find(query)
      .sort({
        createdAt: -1,
      })
      .lean();

    const leadIds = leads.map((lead) => lead._id);

    // ========================================================
    // GET SEQUENCE DELIVERIES
    // ========================================================

    const deliveries = leadIds.length
      ? await SEQUENCE_DELIVERY.find({
          userId,
          leadId: { $in: leadIds },
        })
          .sort({
            createdAt: -1,
          })
          .lean()
      : [];

    // ========================================================
    // TRACKING BY LEAD
    // ========================================================

    const trackingByLead = new Map();

    for (const delivery of deliveries) {
      if (!delivery.leadId) {
        continue;
      }

      const leadId = delivery.leadId.toString();

      if (trackingByLead.has(leadId)) {
        continue;
      }

      let trackingStatus = "Sent";

      // ======================================================
      // OPENED
      // ======================================================

      if (delivery.openedAt) {
        trackingStatus = "Opened";
      }

      // ======================================================
      // FAILED
      // ======================================================
      else if (delivery.status === "failed") {
        trackingStatus = "Failed";
      }

      // ======================================================
      // CLICKED
      // ======================================================
      else if (
        delivery.clickedAt ||
        delivery.clickAt ||
        delivery.clickCount > 0 ||
        delivery.clickedCount > 0
      ) {
        trackingStatus = "Clicked";
      }

      // ======================================================
      // PENDING
      // ======================================================
      else if (delivery.status === "pending") {
        trackingStatus = "Pending";
      }

      // ======================================================
      // SENT
      // ======================================================
      else {
        trackingStatus = "Sent";
      }

      trackingByLead.set(leadId, trackingStatus);
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

    if (!EMAIL_REGEX.test(normalizedEmail)) {
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

    if (!EMAIL_REGEX.test(newEmail)) {
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
    // FILE REQUIRED
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
        .map((lead) => normalizeText(lead.email).toLowerCase())
        .filter(Boolean),
    );

    // ========================================================
    // PROCESS ROWS
    // ========================================================

    const validLeads = [];

    const errors = [];

    const importedEmails = new Set();

    // ========================================================
    // PROCESS EACH ROW
    // ========================================================

    for (let index = 0; index < rows.length; index++) {
      const row = rows[index];

      const excelRowNumber = index + 2;

      // ======================================================
      // READ EXCEL DATA
      // ======================================================

      let firstName = normalizeText(
        getValue(row, ["First Name", "firstName", "FirstName", "FIRST NAME"]),
      );

      let lastName = normalizeText(
        getValue(row, ["Last Name", "lastName", "LastName", "LAST NAME"]),
      );

      const email = normalizeText(
        getValue(row, ["Email", "email", "EMAIL", "E-mail", "E-Mail"]),
      ).toLowerCase();

      let company = normalizeText(
        getValue(row, ["Company", "company", "COMPANY"]),
      );

      const typeValue = normalizeText(
        getValue(row, ["Type", "type", "TYPE"]),
      ).toLowerCase();

      // ======================================================
      // EMAIL REQUIRED
      // ======================================================

      if (!email) {
        errors.push({
          row: excelRowNumber,
          email: "",
          message: "Email is required.",
        });

        continue;
      }

      // ======================================================
      // EMAIL FORMAT
      // ======================================================

      if (!EMAIL_REGEX.test(email)) {
        errors.push({
          row: excelRowNumber,
          email,
          message: "Invalid email address.",
        });

        continue;
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

        continue;
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

        continue;
      }

      importedEmails.add(email);

      // ======================================================
      // IMPORTANT:
      //
      // ONLY PREDICT WHEN THERE ARE NO NAME DETAILS.
      //
      // If Excel already has:
      //
      // First Name = John
      // Last Name  = Doe
      //
      // prediction is NOT executed.
      // ======================================================

      const hasNameDetails = firstName.length > 0 || lastName.length > 0;

      if (!hasNameDetails) {
        const prediction = await predictMissingLeadDetails(email);

        // ====================================================
        // USE PREDICTED FIRST NAME
        // ====================================================

        if (!firstName && prediction.firstName) {
          firstName = prediction.firstName;
        }

        // ====================================================
        // USE PREDICTED LAST NAME
        // ====================================================

        if (!lastName && prediction.lastName) {
          lastName = prediction.lastName;
        }

        // ====================================================
        // USE PREDICTED COMPANY
        //
        // Existing Excel company always has priority.
        // ====================================================

        if (!company && prediction.company) {
          company = prediction.company;
        }

        // ====================================================
        // UNKNOWN PERSON
        //
        // If predictor identifies the email as unknown,
        // use "-" instead of leaving the name empty.
        // ====================================================

        if (!firstName && !lastName && !company) {
          firstName = "-";
          lastName = "-";
        }
      }

      // ======================================================
      // FINAL NAME FALLBACK
      // ======================================================

      if (!firstName && !lastName) {
        firstName = "-";
        lastName = "-";
      }

      // ======================================================
      // TYPE
      // ======================================================

      const type = typeValue === "whatsapp" ? "WhatsApp" : "Email";

      // ======================================================
      // CREATE LEAD
      //
      // TRACKING IS NOT TAKEN FROM EXCEL.
      // DEFAULT = TRUE.
      // ======================================================

      validLeads.push({
        userId,

        firstName,

        lastName,

        email,

        company,

        type,

        tracking: true,
      });
    }

    // ========================================================
    // INSERT
    // ========================================================

    let insertedLeads = [];

    if (validLeads.length > 0) {
      insertedLeads = await LEADS_COLLECTION.insertMany(validLeads, {
        ordered: false,
      });
    }

    // ========================================================
    // SUCCESS RESPONSE
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

    // ========================================================
    // SEND FILE
    // ========================================================

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
