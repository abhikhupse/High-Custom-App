const jwt = require("jsonwebtoken");

const User = require("../model/user.model");
const { denied } = require("./user-access");
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

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const account = await User.findById(decoded.id).select('email isActive deletedAt appRights accessRight').lean();
    const reason = denied(account, req.originalUrl || req.url, req.method);
    if (reason) return res.status(403).json({ success: false, message: reason });
    req.user = { ...decoded, email: account.email };

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
