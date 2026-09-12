const mongoose = require("mongoose");
const User = require("../model/user.model");
const Lead = require("../model/leads.model");
const Delivery = require("../model/sequence_delivery.model");
const SocialLink = require("../model/socialLink.model");

function dateRange(query) {
  const startDate = query.startDate ? new Date(query.startDate) : null;
  const endDate = query.endDate ? new Date(query.endDate) : null;
  if (startDate && Number.isNaN(startDate.getTime())) throw new Error("Invalid start date.");
  if (endDate && Number.isNaN(endDate.getTime())) throw new Error("Invalid end date.");
  if (startDate) startDate.setHours(0, 0, 0, 0);
  if (endDate) endDate.setHours(23, 59, 59, 999);
  if (!startDate && !endDate) return null;
  return { ...(startDate && { $gte: startDate }), ...(endDate && { $lte: endDate }) };
}

function userFilter(userId) {
  if (!userId) return {};
  if (!mongoose.isValidObjectId(userId)) throw new Error("Invalid user.");
  return { userId: new mongoose.Types.ObjectId(userId) };
}

exports.getDashboard = async (req, res) => {
  try {
    const selectedUser = userFilter(req.query.userId);
    const range = dateRange(req.query);
    const deliveryMatch = { ...selectedUser, ...(range && { createdAt: range }) };
    const leadMatch = { ...selectedUser, ...(range && { createdAt: range }) };

    const [users, deliveryStats, totalLeads, todayLeads, linkStats, platforms, buttons] = await Promise.all([
      User.find({}).select("firstName lastName email employerCode").sort({ firstName: 1 }).lean(),
      Delivery.aggregate([
        { $match: deliveryMatch },
        { $group: {
          _id: null,
          totalMails: { $sum: 1 },
          pending: { $sum: { $cond: [{ $eq: ["$status", "pending"] }, 1, 0] } },
          sent: { $sum: { $cond: [{ $eq: ["$status", "sent"] }, 1, 0] } },
          failed: { $sum: { $cond: [{ $eq: ["$status", "failed"] }, 1, 0] } },
          opened: { $sum: { $cond: [{ $ne: ["$openedAt", null] }, 1, 0] } },
          replied: { $sum: { $cond: [{ $ne: ["$repliedAt", null] }, 1, 0] } },
          interested: { $sum: { $cond: [{ $eq: ["$response", "interested"] }, 1, 0] } },
          notInterested: { $sum: { $cond: [{ $eq: ["$response", "notInterested"] }, 1, 0] } },
        } },
      ]),
      Lead.countDocuments(leadMatch),
      Lead.countDocuments({ ...selectedUser, createdAt: { $gte: new Date(new Date().setHours(0, 0, 0, 0)), $lte: new Date(new Date().setHours(23, 59, 59, 999)) } }),
      SocialLink.aggregate([
        { $match: selectedUser },
        { $group: { _id: null, qrScans: { $sum: "$qrScans" }, linkClicks: { $sum: "$linkClicks" } } },
      ]),
      SocialLink.aggregate([
        { $match: selectedUser },
        { $group: { _id: { $ifNull: ["$platform", "Other"] }, count: { $sum: "$linkClicks" } } },
        { $sort: { count: -1, _id: 1 } }, { $limit: 8 },
      ]),
      SocialLink.aggregate([
        { $match: selectedUser },
        { $group: { _id: "$name", count: { $sum: "$linkClicks" } } },
        { $sort: { count: -1, _id: 1 } }, { $limit: 6 },
      ]),
    ]);

    const summary = deliveryStats[0] || {};
    const links = linkStats[0] || {};
    return res.status(200).json({
      success: true,
      users: users.map((user) => ({
        id: user._id,
        name: `${user.firstName || ""} ${user.lastName || ""}`.trim() || user.email,
        email: user.email,
        employerCode: user.employerCode,
      })),
      stats: {
        totalUsers: users.length,
        totalLeads,
        todayLeads,
        totalMails: summary.totalMails || 0,
        pending: summary.pending || 0,
        sent: summary.sent || 0,
        opened: summary.opened || 0,
        failed: summary.failed || 0,
        interested: summary.interested || 0,
        notInterested: summary.notInterested || 0,
        replied: summary.replied || 0,
        clicked: links.linkClicks || 0,
        qrScans: links.qrScans || 0,
      },
      charts: {
        campaign: summary,
        platforms: platforms.map((item) => ({ label: item._id || "Other", value: item.count || 0 })),
        buttons: buttons.map((item) => ({ label: item._id || "Untitled link", value: item.count || 0 })),
      },
    });
  } catch (error) {
    const status = error.message.startsWith("Invalid") ? 400 : 500;
    return res.status(status).json({ success: false, message: error.message || "Unable to load dashboard." });
  }
};
