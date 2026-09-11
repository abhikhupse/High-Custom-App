function normalizeEmails(value) {
  return String(value || "")
    .split(",")
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
}

// ============================================================
// ADMIN MIDDLEWARE
// ============================================================

module.exports = (req, res, next) => {
  const allowedEmails = normalizeEmails(process.env.ADMIN_EMAILS);

  const userEmail = String(req.account?.email || req.user?.email || "")
    .trim()
    .toLowerCase();

  const role = req.account?.role || req.user?.role;

  // ========================================================
  // PRIMARY ADMIN FROM ENV
  // ========================================================

  const isConfiguredAdmin = allowedEmails.includes(userEmail);

  // ========================================================
  // DATABASE ADMIN
  // ========================================================

  const isRoleAdmin = role === "Admin";

  if (!isConfiguredAdmin && !isRoleAdmin) {
    return res.status(403).json({
      success: false,
      message: "Administrator access is required.",
    });
  }

  return next();
};
