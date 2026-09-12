function allowRoles(...allowedRoles) {
  return (req, res, next) => {
    const role = req.account?.role || req.user?.role;

    if (!role || !allowedRoles.includes(role)) {
      return res.status(403).json({
        success: false,
        message: "You do not have permission to access this resource.",
      });
    }

    next();
  };
}

// A primary administrator can be configured through ADMIN_EMAILS even when
// their historical database role is still "User".  Admin workspace pages
// must recognise that configured account alongside the normal Admin/HR roles.
function allowAdminOrRoles(...allowedRoles) {
  return (req, res, next) => {
    const role = req.account?.role || req.user?.role;
    const email = String(req.account?.email || req.user?.email || "")
      .trim()
      .toLowerCase();
    const adminEmails = String(process.env.ADMIN_EMAILS || "")
      .split(",")
      .map((value) => value.trim().toLowerCase())
      .filter(Boolean);

    if (allowedRoles.includes(role) || adminEmails.includes(email)) {
      return next();
    }

    return res.status(403).json({
      success: false,
      message: "You do not have permission to access this resource.",
    });
  };
}

module.exports = {
  allowRoles,
  allowAdminOrRoles,
};
