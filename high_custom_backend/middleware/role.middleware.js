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

module.exports = {
  allowRoles,
};
