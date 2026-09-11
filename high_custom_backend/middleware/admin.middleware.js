function normalizeEmails(value) {
  return String(value || "")
    .split(",")
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
}

module.exports = (req, res, next) => {
  const allowedEmails = normalizeEmails(process.env.ADMIN_EMAILS);
  const userEmail = String(req.user?.email || "").trim().toLowerCase();

  if (!allowedEmails.length) {
    return res.status(403).json({
      success: false,
      message: "Admin access is not configured.",
    });
  }

  if (!userEmail || !allowedEmails.includes(userEmail)) {
    return res.status(403).json({
      success: false,
      message: "Administrator access is required.",
    });
  }

  return next();
};
