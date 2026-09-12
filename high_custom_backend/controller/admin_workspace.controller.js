const mongoose = require("mongoose");
const Lead = require("../model/leads.model");
const Sequence = require("../model/sequence.model");
const Delivery = require("../model/sequence_delivery.model");
const Interest = require("../model/lead_interest_details.model");

const pageOptions = (query) => {
  const page = Math.max(Number.parseInt(query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(Number.parseInt(query.limit, 10) || 25, 1), 100);
  return { page, limit, skip: (page - 1) * limit };
};

const rangeFilter = (query, field = "createdAt") => {
  const value = {};
  if (query.startDate) {
    const date = new Date(query.startDate);
    if (!Number.isNaN(date.getTime())) value.$gte = date;
  }
  if (query.endDate) {
    const date = new Date(query.endDate);
    if (!Number.isNaN(date.getTime())) {
      date.setHours(23, 59, 59, 999);
      value.$lte = date;
    }
  }
  return Object.keys(value).length ? { [field]: value } : {};
};

const owner = (user) => {
  if (!user) return { id: "", name: "—", email: "—" };
  const name = `${user.firstName || ""} ${user.lastName || ""}`.trim();
  return { id: String(user._id || ""), name: name || user.email || "—", email: user.email || "—" };
};

// Company workspace only. These handlers are mounted below auth + requireAdmin;
// the personal workspace routes remain unchanged and continue to use req.user.id.
exports.listLeads = async (req, res) => {
  try {
    const { page, limit, skip } = pageOptions(req.query);
    const search = String(req.query.search || "").trim();
    const status = String(req.query.status || "").trim().toLowerCase();
    const query = { ...rangeFilter(req.query) };

    if (req.query.userId && mongoose.isValidObjectId(req.query.userId)) {
      query.userId = req.query.userId;
    }
    if (req.query.businessType) query.businessType = String(req.query.businessType).trim();
    if (search) {
      const expression = new RegExp(search.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
      query.$or = [
        { firstName: expression }, { lastName: expression }, { email: expression },
        { company: expression }, { businessType: expression },
      ];
    }
    if (status === "interested") query.responseStatus = "interested";
    if (status === "not-interested") query.responseStatus = "notInterested";
    if (status === "pending") { query.responseStatus = null; query.tracking = true; }
    if (status === "skip") query.tracking = false;

    const [rows, total, businessTypes] = await Promise.all([
      Lead.find(query).populate("userId", "firstName lastName email").sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
      Lead.countDocuments(query),
      Lead.distinct("businessType", { businessType: { $nin: [null, ""] } }),
    ]);
    return res.json({
      success: true,
      leads: rows.map((lead) => ({
        ...lead,
        id: lead._id,
        owner: owner(lead.userId),
        trackingStatus: lead.responseStatus === "interested" ? "Interested" : lead.responseStatus === "notInterested" ? "Not Interested" : lead.tracking === false ? "Skip" : "Pending",
      })),
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
      filterOptions: { businessTypes: businessTypes.sort() },
    });
  } catch (error) {
    console.error("ADMIN LIST LEADS ERROR:", error);
    return res.status(500).json({ success: false, message: "Unable to load company leads." });
  }
};

exports.listSequences = async (req, res) => {
  try {
    const { page, limit, skip } = pageOptions(req.query);
    const search = String(req.query.search || "").trim();
    const query = { ...rangeFilter(req.query) };
    if (req.query.userId && mongoose.isValidObjectId(req.query.userId)) query.userId = req.query.userId;
    if (req.query.status) query.status = String(req.query.status).trim();
    if (req.query.businessType) query.businessType = String(req.query.businessType).trim();
    if (search) {
      const expression = new RegExp(search.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
      query.$or = [{ subject: expression }, { variant: expression }, { businessType: expression }, { content: expression }];
    }
    const [rows, total, businessTypes] = await Promise.all([
      Sequence.find(query).populate("userId", "firstName lastName email").sort({ createdAt: -1, step: 1 }).skip(skip).limit(limit).lean(),
      Sequence.countDocuments(query),
      Sequence.distinct("businessType", { businessType: { $nin: [null, ""] } }),
    ]);
    return res.json({
      success: true,
      data: rows.map((sequence) => ({
        ...sequence,
        owner: owner(sequence.userId),
        channel: sequence.channel || "Email",
        businessType: sequence.businessType || "",
      })),
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
      filterOptions: { businessTypes: businessTypes.sort() },
    });
  } catch (error) {
    console.error("ADMIN LIST SEQUENCES ERROR:", error);
    return res.status(500).json({ success: false, message: "Unable to load company sequences." });
  }
};

exports.updateSequence = async (req, res) => {
  try {
    const { sequenceId } = req.params;
    if (!mongoose.isValidObjectId(sequenceId))
      return res.status(400).json({ success: false, message: "Invalid sequence id." });
    const allowed = ["subject", "variant", "gapDays", "businessType", "status", "content"];
    const updates = {};
    for (const key of allowed) {
      if (req.body?.[key] !== undefined) updates[key] = req.body[key];
    }
    if (updates.gapDays !== undefined) updates.gapDays = Math.max(0, Number(updates.gapDays) || 0);
    if (updates.variant !== undefined) updates.variant = String(updates.variant).trim().toUpperCase();
    if (updates.status !== undefined && !["draft", "active", "paused", "completed"].includes(updates.status))
      return res.status(400).json({ success: false, message: "Invalid sequence status." });
    const sequence = await Sequence.findByIdAndUpdate(sequenceId, { $set: updates }, { new: true }).lean();
    if (!sequence) return res.status(404).json({ success: false, message: "Sequence not found." });
    return res.json({ success: true, data: sequence });
  } catch (error) {
    console.error("ADMIN UPDATE SEQUENCE ERROR:", error);
    return res.status(500).json({ success: false, message: "Unable to update sequence." });
  }
};

exports.deleteSequence = async (req, res) => {
  try {
    const { sequenceId } = req.params;
    if (!mongoose.isValidObjectId(sequenceId))
      return res.status(400).json({ success: false, message: "Invalid sequence id." });
    const sequence = await Sequence.findByIdAndDelete(sequenceId).lean();
    if (!sequence) return res.status(404).json({ success: false, message: "Sequence not found." });
    return res.json({ success: true, message: "Sequence deleted." });
  } catch (error) {
    console.error("ADMIN DELETE SEQUENCE ERROR:", error);
    return res.status(500).json({ success: false, message: "Unable to delete sequence." });
  }
};

exports.listInterestedLeads = async (req, res) => {
  try {
    const { page, limit, skip } = pageOptions(req.query);
    const query = { ...rangeFilter(req.query, "submittedAt") };
    if (req.query.userId && mongoose.isValidObjectId(req.query.userId)) query.userId = req.query.userId;
    if (req.query.businessType) {
      const leads = await Lead.find({ businessType: String(req.query.businessType).trim() }).select("_id").lean();
      query.leadId = { $in: leads.map((lead) => lead._id) };
    }
    if (req.query.search && String(req.query.search).trim()) {
      const expression = new RegExp(String(req.query.search).trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
      const matchingLeads = await Lead.find({ $or: [{ firstName: expression }, { lastName: expression }, { email: expression }, { company: expression }] }).select("_id").lean();
      query.$or = [{ name: expression }, { mobileNumber: expression }, { companyName: expression }, { city: expression }, { state: expression }, { country: expression }, { leadId: { $in: matchingLeads.map((lead) => lead._id) } }];
    }
    const [details, total, businessTypes] = await Promise.all([
      Interest.find(query).populate("userId", "firstName lastName email").populate("leadId", "firstName lastName email company businessType").populate("sequenceId", "subject step variant").sort({ submittedAt: -1 }).skip(skip).limit(limit).lean(),
      Interest.countDocuments(query),
      Lead.distinct("businessType", { businessType: { $nin: [null, ""] } }),
    ]);
    return res.json({ success: true, details: details.map((item) => ({ ...item, owner: owner(item.userId) })), pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }, filterOptions: { businessTypes: businessTypes.sort() } });
  } catch (error) {
    console.error("ADMIN LIST INTERESTED LEADS ERROR:", error);
    return res.status(500).json({ success: false, message: "Unable to load company interested leads." });
  }
};

// Company-wide Admin action. The original Lead remains intact; only its
// submitted interested-response record is removed from this report.
exports.deleteInterestedLead = async (req, res) => {
  try {
    const { interestId } = req.params;
    if (!mongoose.isValidObjectId(interestId))
      return res.status(400).json({ success: false, message: "Invalid interested lead id." });
    const detail = await Interest.findByIdAndDelete(interestId).lean();
    if (!detail) return res.status(404).json({ success: false, message: "Interested lead record not found." });
    return res.json({ success: true, message: "Interested lead record deleted." });
  } catch (error) {
    console.error("ADMIN DELETE INTERESTED LEAD ERROR:", error);
    return res.status(500).json({ success: false, message: "Unable to delete interested lead record." });
  }
};
