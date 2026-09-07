const BusinessLinkSettings = require("../model/businessLinkSettings.model");
const SocialLink = require("../model/socialLink.model");
const User = require("../model/user.model");
const Sequence = require("../model/sequence.model");

function getPublicBaseUrl(req) {
  return String(process.env.PUBLIC_BASE_URL || `${req.protocol}://${req.get("host")}`).replace(/\/$/, "");
}

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
    const links = await SocialLink.find({ _id: { $in: ids }, userId: req.user.id })
      .select("name url")
      .lean();
    const logoUrl = `${getPublicBaseUrl(req)}/uploads/brand/high_custom_logo.png`;
    const whatsappUrl = `https://wa.me/${digits}`;
    const primaryLink = links.find((link) => /^https?:\/\//i.test(link.url || ""));
    const data = await BusinessLinkSettings.findOneAndUpdate(
      { userId: req.user.id, businessType },
      { $set: {
        logoKey: "high_custom_logo",
        logoUrl,
        whatsappUrl,
        actionLinkIds: links.map((link) => link._id),
        actionLinkNames: links.map((link) => link.name),
        actionLinks: links.map((link) => ({ id: link._id, name: link.name, url: link.url })),
      } },
      { upsert: true, new: true, runValidators: true },
    );
    await Sequence.updateMany(
      { userId: req.user.id, businessType },
      { $set: {
        brand: { enabled: true, logoUrl, logoPosition: "Center" },
        actionLinks: {
          whatsapp: { enabled: true, url: whatsappUrl },
          cta: primaryLink
            ? { enabled: true, text: primaryLink.name, url: primaryLink.url }
            : { enabled: false, text: null, url: null },
        },
      } },
    );
    return res.json({ success: true, data, message: "Business details saved for this business type." });
  } catch (_) { return res.status(500).json({ success: false, message: "Unable to save business details." }); }
};
