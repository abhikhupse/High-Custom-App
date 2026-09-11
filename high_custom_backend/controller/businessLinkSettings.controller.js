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
    const data = await BusinessLinkSettings.findOne({ userId: req.user.id, businessType: businessType || "__all__" }).lean()
      || (businessType ? await BusinessLinkSettings.findOne({ userId: req.user.id, businessType: "__all__" }).lean() : null);
    return res.json({ success: true, data: data || null });
  } catch (_) { return res.status(500).json({ success: false, message: "Unable to load business details." }); }
};

exports.save = async (req, res) => {
  try {
    const selectedBusinessType = String(req.body.businessType || "").trim();
    const businessType = selectedBusinessType || "__all__";
    const ids = Array.isArray(req.body.actionLinkIds) ? req.body.actionLinkIds : [];
    const user = await User.findById(req.user.id).select("phone").lean();
    const digits = String(user?.phone || "").replace(/\D/g, "");
    if (!digits) return res.status(400).json({ success: false, message: "Registered mobile number not found." });
    const links = await SocialLink.find({ _id: { $in: ids }, userId: req.user.id })
      .select("name url")
      .lean();
    const logoUrl = `${getPublicBaseUrl(req)}/uploads/brand/high_custom_logo.png`;
    const whatsappUrl = `https://wa.me/${digits}`;
    const primaryLink = links.find((link) => /^https?:\/\//i.test(link.url || ""));
    // An empty business type represents the shared/default configuration.
    // Keep it in a dedicated record instead of overwriting an arbitrary type.
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
    // A type-specific save changes only that type. A blank selection is the
    // "all sequences" option used by the Flutter Link screen.
    await Sequence.updateMany(
      selectedBusinessType
        ? { userId: req.user.id, businessType }
        : { userId: req.user.id },
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
    return res.json({ success: true, data, message: selectedBusinessType ? "Business details saved for this business type." : "Business details saved for all sequences." });
  } catch (_) { return res.status(500).json({ success: false, message: "Unable to save business details." }); }
};
