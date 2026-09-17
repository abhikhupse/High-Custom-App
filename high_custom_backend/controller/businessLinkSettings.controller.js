const BusinessLinkSettings = require("../model/businessLinkSettings.model");
const SocialLink = require("../model/socialLink.model");
const User = require("../model/user.model");
const Sequence = require("../model/sequence.model");

function linkType(link = {}) {
  const value =
    `${link.platform || ""} ${link.name || ""} ${link.url || ""}`.toLowerCase();
  if (value.includes("instagram")) return "instagram";
  // The report uses one Facebook Messenger column, so legacy Facebook links
  // and Messenger links must contribute to the same tracked counter.
  if (value.includes("messenger") || value.includes("facebook"))
    return "messenger";
  if (value.includes("threads")) return "threads";
  if (value.includes("telegram")) return "telegram";
  if (value.includes("linkedin")) return "linkedin";
  if (/(^|[^a-z])x([^a-z]|$)|twitter/.test(value)) return "x";
  return "website";
}

function getPublicBaseUrl(req) {
  return String(
    process.env.PUBLIC_BASE_URL || `${req.protocol}://${req.get("host")}`,
  ).replace(/\/$/, "");
}

exports.get = async (req, res) => {
  try {
    const businessType = String(req.query.businessType || "").trim();
    const data =
      (await BusinessLinkSettings.findOne({
        userId: req.user.id,
        businessType: businessType || "__all__",
      }).lean()) ||
      (businessType
        ? await BusinessLinkSettings.findOne({
            userId: req.user.id,
            businessType: "__all__",
          }).lean()
        : null) ||
      // The sequence form opens before a Business Type is necessarily chosen.
      // In that case show the Admin's most recently saved Brand Link kit.
      (!businessType
        ? await BusinessLinkSettings.findOne({ userId: req.user.id })
            .sort({ updatedAt: -1 })
            .lean()
        : null);
    return res.json({ success: true, data: data || null });
  } catch (_) {
    return res
      .status(500)
      .json({ success: false, message: "Unable to load business details." });
  }
};

exports.setLogoPreference = async (req, res) => {
  try {
    const logoEnabled = req.body?.logoEnabled === true;
    // This is an Admin-level default, so it applies to every business type.
    await BusinessLinkSettings.updateMany(
      { userId: req.user.id },
      { $set: { logoSuppressed: !logoEnabled } },
    );
    return res.json({ success: true, logoSuppressed: !logoEnabled });
  } catch (_) {
    return res
      .status(500)
      .json({ success: false, message: "Unable to update logo preference." });
  }
};

exports.save = async (req, res) => {
  try {
    const selectedBusinessType = String(req.body.businessType || "").trim();
    const businessType = selectedBusinessType || "__all__";
    const ids = Array.isArray(req.body.actionLinkIds)
      ? req.body.actionLinkIds
      : [];
    const user = await User.findById(req.user.id).select("phone").lean();
    const digits = String(user?.phone || "").replace(/\D/g, "");
    if (!digits)
      return res
        .status(400)
        .json({
          success: false,
          message: "Registered mobile number not found.",
        });
    const links = await SocialLink.find({
      _id: { $in: ids },
      userId: req.user.id,
    })
      .select("name url platform")
      .lean();
    const logoUrl = `${getPublicBaseUrl(req)}/uploads/brand/high_custom_logo.png`;
    const whatsappUrl = `https://wa.me/${digits}`;
    const primaryLink = links.find((link) =>
      /^https?:\/\//i.test(link.url || ""),
    );
    // An empty business type represents the shared/default configuration.
    // Keep it in a dedicated record instead of overwriting an arbitrary type.
    const data = await BusinessLinkSettings.findOneAndUpdate(
      { userId: req.user.id, businessType },
      {
        $set: {
          logoKey: "high_custom_logo",
          logoUrl,
          logoSuppressed: false,
          whatsappUrl,
          actionLinkIds: links.map((link) => link._id),
          actionLinkNames: links.map((link) => link.name),
          actionLinks: links.map((link) => ({
            id: link._id,
            name: link.name,
            url: link.url,
          })),
        },
      },
      { upsert: true, new: true, runValidators: true },
    );
    // A type-specific save changes only that type. A blank selection is the
    // "all sequences" option used by the Flutter Link screen.
    await Sequence.updateMany(
      selectedBusinessType
        ? { userId: req.user.id, businessType }
        : { userId: req.user.id },
      {
        $set: {
          brand: { enabled: true, logoUrl, logoPosition: "Center" },
          "tracking.trackActionLinks": true,
          actionLinks: {
            whatsapp: { enabled: true, url: whatsappUrl },
            cta: primaryLink
              ? { enabled: true, text: primaryLink.name, url: primaryLink.url }
              : { enabled: false, text: null, url: null },
            // The first selected link remains the primary CTA. Every remaining
            // selected social link is included in the message with its own
            // tracking route and delivery-level counter.
            links: links
              .filter((link) => String(link._id) !== String(primaryLink?._id))
              .map((link) => ({
                type: linkType(link),
                label: link.name,
                url: link.url,
                enabled: true,
              }))
              .filter((link) => link.type !== "website"),
          },
        },
      },
    );
    return res.json({
      success: true,
      data,
      message: selectedBusinessType
        ? "Business details saved for this business type."
        : "Business details saved for all sequences.",
    });
  } catch (_) {
    return res
      .status(500)
      .json({ success: false, message: "Unable to save business details." });
  }
};
