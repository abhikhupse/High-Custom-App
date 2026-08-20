const LEADS_COLLECTION = require("../model/leads.model");
const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");
const XLSX = require("xlsx");
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
      existingLeads.map((lead) => lead.email.trim().toLowerCase()),
    );

    // ========================================================
    // PROCESS EXCEL ROWS
    // ========================================================

    const validLeads = [];
    const errors = [];
    const importedEmails = new Set();

    rows.forEach((row, index) => {
      const excelRowNumber = index + 2;

      const firstName = String(
        getValue(row, ["First Name", "firstName", "FirstName"]),
      ).trim();

      const lastName = String(
        getValue(row, ["Last Name", "lastName", "LastName"]),
      ).trim();

      const email = String(getValue(row, ["Email", "email"]))
        .trim()
        .toLowerCase();

      const company = String(getValue(row, ["Company", "company"])).trim();

      const typeValue = String(getValue(row, ["Type", "type"]))
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
      // DUPLICATE DATABASE CHECK
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
      // DUPLICATE EXCEL CHECK
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
      // TYPE
      // ======================================================

      const type = typeValue === "whatsapp" ? "WhatsApp" : "Email";

      // ======================================================
      // CREATE LEAD
      //
      // TRACKING IS NOT TAKEN FROM EXCEL.
      // Default = true.
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
    });

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
        wch: 25,
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
    // RESPONSE
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
