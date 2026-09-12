const jwt = require("jsonwebtoken");

const User = require("../model/user.model");

const {
  denied,
  getAppRights,
  getAccessRights,
  getDataScope,
} = require("./user-access");

// ============================================================
// AUTH MIDDLEWARE
// ============================================================

const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.get("Authorization");

    if (!authHeader) {
      return res.status(401).json({
        success: false,
        message: "Authorization token is required",
      });
    }

    if (!authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
        success: false,
        message: "Invalid authorization format",
      });
    }

    const token = authHeader.substring(7).trim();

    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Token is missing",
      });
    }

    // ========================================================
    // VERIFY JWT
    // ========================================================

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // ========================================================
    // LOAD ACCOUNT
    // ========================================================

    const account = await User.findById(decoded.id)
      .select(
        [
          "firstName",
          "lastName",
          "email",
          "role",
          "dataScope",
          "isActive",
          "deletedAt",
          "appRights",
          "accessRights",
          "accessRight",
        ].join(" "),
      )
      .lean();

    const configuredAdminEmails = String(process.env.ADMIN_EMAILS || "")
      .split(",")
      .map((email) => email.trim().toLowerCase())
      .filter(Boolean);
    const effectiveRole = configuredAdminEmails.includes(
      String(account.email || "")
        .trim()
        .toLowerCase(),
    )
      ? "Admin"
      : account.role;
    const rightsAccount = { ...account, role: effectiveRole };

    // ========================================================
    // VALIDATE ACCOUNT
    // ========================================================

    const reason = denied(account);

    if (reason) {
      return res.status(403).json({
        success: false,
        message: reason,
      });
    }

    // ========================================================
    // STORE USER
    // ========================================================

    req.account = rightsAccount;

    req.user = {
      ...decoded,

      id: String(account._id),

      email: account.email,

      role: effectiveRole,

      dataScope: getDataScope(rightsAccount),

      appRights: getAppRights(rightsAccount),

      accessRights: getAccessRights(rightsAccount),
    };

    next();
  } catch (error) {
    console.error("JWT ERROR:", error.message);

    return res.status(401).json({
      success: false,
      message: "Invalid or expired token",
    });
  }
};

module.exports = authMiddleware;
