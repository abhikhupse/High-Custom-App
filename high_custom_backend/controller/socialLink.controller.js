const QRCode = require("qrcode");
const SocialLink = require("../model/socialLink.model");

const publicBaseUrl =
  process.env.PUBLIC_API_URL || "https://high-custom-app.onrender.com";

const instagramProfileDeepLink = (url) => {
  try {
    const parsed = new URL(url);
    const host = parsed.hostname.toLowerCase().replace(/^www\./, "");
    if (host !== "instagram.com") return null;

    const segments = parsed.pathname.split("/").filter(Boolean);
    const username = segments[0];
    const reservedPaths = new Set(["p", "reel", "reels", "stories", "explore"]);
    if (!username || reservedPaths.has(username.toLowerCase())) return null;

    return `instagram://user?username=${encodeURIComponent(username)}`;
  } catch (_) {
    return null;
  }
};

const sendInstagramRedirect = (res, deepLink, fallbackUrl) => {
  const safeJson = (value) =>
    JSON.stringify(value).replace(/</g, "\\u003c");

  return res
    .status(200)
    .type("html")
    .send(`<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><p>Opening Instagram…</p><script>window.location.href=${safeJson(deepLink)};window.setTimeout(function(){window.location.replace(${safeJson(fallbackUrl)});},1200);</script><a href=${safeJson(fallbackUrl)}>Open Instagram in browser</a></body></html>`);
};

const escapeHtml = (value) =>
  String(value || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");

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
    const allLinksTarget = `${publicBaseUrl}/api/social-links/all-links/${req.user.id}`;
    const allLinksQr = {
      _id: "all-links",
      fixedCard: true,
      name: "All Links",
      qrTitle: "All Links",
      qrCode: await QRCode.toDataURL(allLinksTarget, { width: 600, margin: 2 }),
      qrTarget: allLinksTarget,
      trackingTarget: allLinksTarget,
    };
    return res.json({
      success: true,
      data: [allLinksQr, ...links.map(cleanLink)],
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Unable to load QR codes." });
  }
};

exports.allLinksPage = async (req, res) => {
  try {
    const links = await SocialLink.find({ userId: req.params.userId })
      .sort({ createdAt: -1 })
      .lean();

    const cards = links.length
      ? links
          .map(
            (link) => `<a class="link-card" href="${escapeHtml(`${publicBaseUrl}/api/social-links/r/${link._id}?source=link`)}"><span>${escapeHtml(link.name)}</span><small>${escapeHtml(link.url)}</small><b>Open</b></a>`,
          )
          .join("")
      : '<p class="empty">No links have been added yet.</p>';

    return res.status(200).type("html").send(`<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><title>High Custom</title><style>body{margin:0;background:#090a0c;color:#fff;font-family:Arial,sans-serif}.page{max-width:560px;margin:auto;padding:36px 20px 48px}.brand{color:#f2c45f;letter-spacing:3px;font-size:13px;font-weight:700}.title{font-size:30px;margin:10px 0 8px}.sub{color:#a6a8ae;margin:0 0 26px}.link-card{display:block;background:#151619;border:1px solid #282a30;border-radius:16px;padding:17px;margin:12px 0;color:#fff;text-decoration:none}.link-card span{display:block;font-size:17px;font-weight:700}.link-card small{display:block;color:#a6a8ae;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin:7px 0 14px}.link-card b{color:#f2c45f;font-size:13px}.empty{color:#a6a8ae}</style></head><body><main class="page"><div class="brand">HIGH CUSTOM</div><h1 class="title">All Links</h1><p class="sub">Choose a link to continue.</p>${cards}</main></body></html>`);
  } catch (_) {
    return res.status(404).send("Links not found.");
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

    const instagramDeepLink = instagramProfileDeepLink(link.url);
    if (instagramDeepLink) {
      return sendInstagramRedirect(res, instagramDeepLink, link.url);
    }

    return res.redirect(302, link.url);
  } catch (_) {
    return res.status(404).send("Link not found.");
  }
};
