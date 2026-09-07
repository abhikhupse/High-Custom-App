const QRCode = require("qrcode");
const SocialLink = require("../model/socialLink.model");

const publicBaseUrl =
  process.env.PUBLIC_API_URL || "https://high-custom-app.onrender.com";

const cleanLink = (item) => ({
  _id: item._id,
  name: item.name,
  url: item.url,
  category: item.category,
  platform: item.platform,
  selected: item.selected,
  qrCode: item.qrCode,
  qrTarget: item.qrTarget,
  trackingTarget:
    item.trackingTarget ||
    String(item.qrTarget || "").replace("source=qr", "source=link"),
  qrTitle: item.qrTitle,
  qrGeneratedAt: item.qrGeneratedAt,
  linkClicks: item.linkClicks,
  qrScans: item.qrScans,
  createdAt: item.createdAt,
  updatedAt: item.updatedAt,
});

exports.list = async (req, res) => {
  try {
    const links = await SocialLink.find({ userId: req.user.id })
      .sort({ createdAt: -1 })
      .lean();
    return res.json({ success: true, data: links.map(cleanLink) });
  } catch (error) {
    console.error("LIST SOCIAL LINKS ERROR:", error);
    return res.status(500).json({ success: false, message: "Unable to load links." });
  }
};

exports.create = async (req, res) => {
  try {
    const name = typeof req.body.name === "string" ? req.body.name.trim() : "";
    const url = typeof req.body.url === "string" ? req.body.url.trim() : "";
    const platform = typeof req.body.platform === "string" ? req.body.platform.trim() : "";
    if (!name || !url || !/^https?:\/\//i.test(url)) {
      return res.status(400).json({ success: false, message: "Enter a valid link name and URL." });
    }
    const link = await SocialLink.create({
      userId: req.user.id,
      name,
      url,
      platform,
      category: "custom",
    });
    return res.status(201).json({ success: true, data: cleanLink(link) });
  } catch (error) {
    console.error("CREATE SOCIAL LINK ERROR:", error);
    return res.status(500).json({ success: false, message: "Unable to add link." });
  }
};

exports.update = async (req, res) => {
  try {
    const link = await SocialLink.findOne({ _id: req.params.id, userId: req.user.id });
    if (!link) return res.status(404).json({ success: false, message: "Link not found." });
    const { name, url, selected, qrTitle } = req.body;
    if (name !== undefined) link.name = String(name).trim();
    if (url !== undefined) {
      const value = String(url).trim();
      if (!/^https?:\/\//i.test(value)) {
        return res.status(400).json({ success: false, message: "Enter a valid URL." });
      }
      link.url = value;
      link.qrCode = "";
      link.qrTarget = "";
      link.trackingTarget = "";
      link.qrGeneratedAt = undefined;
    }
    if (selected !== undefined) link.selected = selected === true;
    if (qrTitle !== undefined) link.qrTitle = String(qrTitle).trim().slice(0, 80);
    await link.save();
    return res.json({ success: true, data: cleanLink(link) });
  } catch (error) {
    console.error("UPDATE SOCIAL LINK ERROR:", error);
    return res.status(500).json({ success: false, message: "Unable to update link." });
  }
};

exports.remove = async (req, res) => {
  try {
    const link = await SocialLink.findOneAndDelete({ _id: req.params.id, userId: req.user.id });
    if (!link) return res.status(404).json({ success: false, message: "Link not found." });
    return res.json({ success: true, message: "Link deleted." });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Unable to delete link." });
  }
};

exports.generateQr = async (req, res) => {
  try {
    const ids = Array.isArray(req.body.linkIds) ? req.body.linkIds : [];
    const links = await SocialLink.find({ _id: { $in: ids }, userId: req.user.id });
    await Promise.all(links.map(async (link) => {
      const redirectBase = `${publicBaseUrl}/api/social-links/r/${link._id}`;
      const qrTarget = `${redirectBase}?source=qr`;
      link.qrTarget = qrTarget;
      link.trackingTarget = `${redirectBase}?source=link`;
      if (!link.qrTitle) link.qrTitle = link.name;
      link.qrCode = await QRCode.toDataURL(qrTarget, { width: 600, margin: 2 });
      link.qrGeneratedAt = new Date();
      await link.save();
    }));
    return res.json({ success: true, data: links.map(cleanLink) });
  } catch (error) {
    console.error("GENERATE SOCIAL QR ERROR:", error);
    return res.status(500).json({ success: false, message: "Unable to generate QR codes." });
  }
};

exports.listQr = async (req, res) => {
  try {
    const links = await SocialLink.find({ userId: req.user.id, qrCode: { $ne: "" } })
      .sort({ qrGeneratedAt: -1 })
      .lean();
    return res.json({ success: true, data: links.map(cleanLink) });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Unable to load QR codes." });
  }
};

exports.deleteQr = async (req, res) => {
  try {
    const link = await SocialLink.findOne({ _id: req.params.id, userId: req.user.id });
    if (!link) return res.status(404).json({ success: false, message: "QR code not found." });
    link.qrCode = "";
    link.qrTarget = "";
    link.trackingTarget = "";
    link.qrTitle = "";
    link.qrGeneratedAt = undefined;
    await link.save();
    return res.json({ success: true, message: "QR code deleted." });
  } catch (_) {
    return res.status(500).json({ success: false, message: "Unable to delete QR code." });
  }
};

exports.redirect = async (req, res) => {
  try {
    const link = await SocialLink.findById(req.params.id);
    if (!link) return res.status(404).send("Link not found.");
    if (req.query.source === "qr") {
      link.qrScans += 1;
    } else {
      link.linkClicks += 1;
    }
    await link.save();
    return res.redirect(302, link.url);
  } catch (_) {
    return res.status(404).send("Link not found.");
  }
};
