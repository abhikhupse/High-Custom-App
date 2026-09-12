const { getRolePermissions } = require("../config/role-permissions");

// ============================================================
// GET EFFECTIVE APP RIGHTS
// ============================================================

function getAppRights(user) {
  const defaults = getRolePermissions(user?.role);

  return {
    ...defaults.appRights,
    ...(user?.appRights || {}),
  };
}

// ============================================================
// GET EFFECTIVE ACCESS RIGHTS
// ============================================================

function getAccessRights(user) {
  const defaults = getRolePermissions(user?.role);

  return {
    ...defaults.accessRights,
    ...(user?.accessRights || {}),
  };
}

// ============================================================
// GET DATA SCOPE
// ============================================================

function getDataScope(user) {
  if (user?.dataScope) {
    return user.dataScope;
  }

  return getRolePermissions(user?.role).dataScope;
}

// ============================================================
// APP CHECK
// ============================================================

function hasAppRight(user, permission) {
  const rights = getAppRights(user);

  return rights[permission] === true;
}

// ============================================================
// ACCESS CHECK
// ============================================================

function hasAccessRight(user, permission) {
  const rights = getAccessRights(user);

  return rights[permission] === true;
}

// ============================================================
// REQUIRE APP RIGHT
// ============================================================

function requireAppRight(permission) {
  return (req, res, next) => {
    if (!hasAppRight(req.account, permission)) {
      return res.status(403).json({
        success: false,
        message: `You do not have access to ${permission}.`,
      });
    }

    next();
  };
}

// ============================================================
// REQUIRE ACCESS RIGHT
// ============================================================

function requireAccessRight(permission) {
  return (req, res, next) => {
    if (!hasAccessRight(req.account, permission)) {
      return res.status(403).json({
        success: false,
        message: "You do not have permission to perform this action.",
        permission,
      });
    }

    next();
  };
}

// ============================================================
// GLOBAL ACCOUNT VALIDATION
// ============================================================

function denied(user) {
  if (!user) {
    return "Account not found.";
  }

  if (user.deletedAt) {
    return "Your account is inactive. Please contact admin.";
  }

  if (user.isActive === false) {
    return "Your account is inactive. Please contact admin.";
  }

  if (user.accessRight === "No Access") {
    return "Your account has no access.";
  }

  return null;
}

// ============================================================
// DATA ACCESS HELPER
// ============================================================

function buildUserDataFilter(req, userIdField = "userId") {
  const scope = getDataScope(req.account);

  // Admin / HR company workspace
  if (scope === "all" || scope === "company") {
    return {};
  }

  // Employee
  return {
    [userIdField]: req.user.id,
  };
}

// ============================================================
// CAN MANAGE USER
// ============================================================

function canManageUser(currentUser, targetUser) {
  if (!currentUser || !targetUser) {
    return false;
  }

  const currentRole = currentUser.role === "User" ? "Employee" : currentUser.role;
  const targetRole = targetUser.role === "User" ? "Employee" : targetUser.role;

  // Admin can manage every account. The controller separately protects
  // administrator status and deletion.
  if (currentRole === "Admin") {
    return true;
  }

  // HR can manage Employees only.
  if (currentRole === "HR") {
    return targetRole === "Employee";
  }

  // Employee cannot manage users.
  return false;
}

module.exports = {
  denied,

  getAppRights,
  getAccessRights,
  getDataScope,

  hasAppRight,
  hasAccessRight,

  requireAppRight,
  requireAccessRight,

  buildUserDataFilter,
  canManageUser,
};
