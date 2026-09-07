const BusinessLinkSettings = require("../model/businessLinkSettings.model");
const SocialLink = require("../model/socialLink.model");
const User = require("../model/user.model");

exports.get = async (req, res) => {
  try {
    const businessType = String(req.query.businessType || "").trim();
    if (!businessType) return res.status(400).json({ success: false, message: "Business type is required." });
    const data = await BusinessLinkSettings.findOne({ userId: req.user.id, businessType }).lean();
    return res.json({ success: true, data: data || null });
  } catch (_) { return res.status(500).json({ success: false, message: "Unable to load business details." }); }
};

exports.save = async (req, res) => {
  try {
    const businessType = String(req.body.businessType || "").trim();
    const ids = Array.isArray(req.body.actionLinkIds) ? req.body.actionLinkIds : [];
    if (!businessType) return res.status(400).json({ success: false, message: "Select a business type." });
    const user = await User.findById(req.user.id).select("phone").lean();
    const digits = String(user?.phone || "").replace(/\D/g, "");
    if (!digits) return res.status(400).json({ success: false, message: "Registered mobile number not found." });
    const links = await SocialLink.find({ _id: { $in: ids }, userId: req.user.id }).select("name").lean();
    const data = await BusinessLinkSettings.findOneAndUpdate(
      { userId: req.user.id, businessType },
      { $set: { logoKey: "high_custom_logo", whatsappUrl: `https://wa.me/${digits}`, actionLinkIds: links.map((link) => link._id), actionLinkNames: links.map((link) => link.name) } },
      { upsert: true, new: true, runValidators: true },
    );
    return res.json({ success: true, data, message: "Business details saved for this business type." });
  } catch (_) { return res.status(500).json({ success: false, message: "Unable to save business details." }); }
};
