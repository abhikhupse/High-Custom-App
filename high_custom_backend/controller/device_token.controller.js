const DeviceToken = require("../model/device_token.model");

exports.register = async (req, res) => {
  const token = String(req.body?.token || "").trim();
  const platform = req.body?.platform === "ios" ? "ios" : "android";
  if (!token) return res.status(400).json({ success: false, message: "Device token is required." });

  try {
    await DeviceToken.findOneAndUpdate(
      { token },
      { $set: { userId: req.user.id, platform, lastSeenAt: new Date() } },
      { upsert: true, returnDocument: "after", setDefaultsOnInsert: true },
    );
    return res.status(200).json({ success: true });
  } catch (_) {
    return res.status(500).json({ success: false, message: "Unable to register device." });
  }
};
