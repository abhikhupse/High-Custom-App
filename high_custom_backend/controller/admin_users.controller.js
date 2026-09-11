const bcrypt = require("bcrypt");
const XLSX = require("xlsx");

const User = require("../model/user.model");

const { getRolePermissions } = require("../config/role-permissions");

const {
  getAppRights,
  getAccessRights,
  canManageUser,
} = require("../middleware/user-access");

// ============================================================
// FIELDS
// ============================================================

const fields = [
  "firstName",
  "lastName",
  "employerCode",
  "email",
  "phone",
  "profileImage",
  "role",
  "dataScope",
  "isActive",
  "appRights",
  "accessRights",
  "createdAt",
].join(" ");

// ============================================================
// ADMIN EMAILS
// ============================================================

function getAdminEmails() {
  return String(process.env.ADMIN_EMAILS || "")
    .split(",")
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
}

function isConfiguredAdmin(email) {
  return getAdminEmails().includes(
    String(email || "")
      .trim()
      .toLowerCase(),
  );
}

// ============================================================
// SERIALIZE
// ============================================================

function serialize(user) {
  const data = user.toObject ? user.toObject() : user;

  const configuredAdmin = isConfiguredAdmin(data.email);

  const effectiveRole = configuredAdmin ? "Admin" : data.role || "Employee";

  return {
    ...data,

    role: effectiveRole,

    isAdministrator: effectiveRole === "Admin",

    isActive: data.isActive !== false,

    appRights: getAppRights({
      ...data,
      role: effectiveRole,
    }),

    accessRights: getAccessRights({
      ...data,
      role: effectiveRole,
    }),

    dataScope: data.dataScope || getRolePermissions(effectiveRole).dataScope,
  };
}

// ============================================================
// LIST USERS
// ============================================================

exports.list = async (req, res, next) => {
  try {
    // Admin + HR are allowed.
    if (!["Admin", "HR"].includes(req.account.role)) {
      return res.status(403).json({
        success: false,
        message: "You do not have permission to view users.",
      });
    }

    const users = await User.find({
      deletedAt: null,
    })
      .select(fields)
      .sort({
        createdAt: -1,
      })
      .lean();

    const data = users.map(serialize).sort((a, b) => {
      const rolePriority = {
        Admin: 3,
        HR: 2,
        Employee: 1,
      };

      return rolePriority[b.role] - rolePriority[a.role];
    });

    return res.json({
      success: true,

      currentUserId: String(req.user.id),

      currentUserRole: req.account.role,

      data,
    });
  } catch (error) {
    next(error);
  }
};

// ============================================================
// UPDATE USER
// ============================================================

exports.update = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!/^[a-f0-9]{24}$/i.test(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid user ID.",
      });
    }

    const user = await User.findOne({
      _id: id,
      deletedAt: null,
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found.",
      });
    }

    // ========================================================
    // PREVENT OWN RIGHTS EDIT
    // ========================================================

    if (String(user._id) === String(req.user.id)) {
      return res.status(403).json({
        success: false,
        message: "You cannot change your own role or permissions here.",
      });
    }

    // ========================================================
    // ROLE HIERARCHY
    // ========================================================

    if (!canManageUser(req.account, user)) {
      return res.status(403).json({
        success: false,
        message: "You do not have permission to manage this user.",
      });
    }

    const body = req.body || {};

    const changes = {};

    const fail = (message, status = 400) =>
      res.status(status).json({
        success: false,
        message,
      });

    // ========================================================
    // NORMAL PROFILE FIELDS
    // ========================================================

    const editableFields = [
      "firstName",
      "lastName",
      "email",
      "phone",
      "employerCode",
    ];

    for (const key of editableFields) {
      if (key in body) {
        if (
          typeof body[key] !== "string" ||
          !body[key].trim() ||
          body[key].length > 200
        ) {
          return fail(`Please enter a valid ${key}.`);
        }

        changes[key] = body[key].trim();
      }
    }

    // ========================================================
    // EMAIL
    // ========================================================

    if (changes.email) {
      changes.email = changes.email.toLowerCase();

      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(changes.email)) {
        return fail("Please enter a valid email.");
      }
    }

    // ========================================================
    // STATUS
    // ========================================================

    if ("isActive" in body) {
      if (typeof body.isActive !== "boolean") {
        return fail("Invalid status.");
      }

      changes.isActive = body.isActive;
    }

    // ========================================================
    // ROLE
    // ========================================================

    if ("role" in body) {
      const role = String(body.role).trim();

      if (!["Admin", "HR", "Employee"].includes(role)) {
        return fail("Invalid role.");
      }

      // HR cannot change roles.
      if (req.account.role === "HR" && role !== "Employee") {
        return fail("HR can only manage Employee accounts.", 403);
      }

      // Only Admin can assign HR.
      if (role === "HR" && req.account.role !== "Admin") {
        return fail("Only Admin can assign HR role.", 403);
      }

      // Don't create another Admin here.
      if (role === "Admin") {
        return fail("Admin role cannot be assigned from User Management.", 403);
      }

      changes.role = role;

      const defaults = getRolePermissions(role);

      changes.dataScope = defaults.dataScope;

      changes.appRights = defaults.appRights;

      changes.accessRights = defaults.accessRights;
    }

    // ========================================================
    // APP RIGHTS
    // ========================================================

    if ("appRights" in body) {
      if (
        !body.appRights ||
        typeof body.appRights !== "object" ||
        Array.isArray(body.appRights)
      ) {
        return fail("Invalid app rights.");
      }

      // HR can modify Employees only.
      if (req.account.role === "HR" && user.role !== "Employee") {
        return fail("HR can change permissions for Employees only.", 403);
      }

      changes.appRights = {
        ...getAppRights(user),
        ...body.appRights,
      };
    }

    // ========================================================
    // ACCESS RIGHTS
    // ========================================================

    if ("accessRights" in body) {
      if (
        !body.accessRights ||
        typeof body.accessRights !== "object" ||
        Array.isArray(body.accessRights)
      ) {
        return fail("Invalid access rights.");
      }

      if (req.account.role === "HR" && user.role !== "Employee") {
        return fail("HR can change permissions for Employees only.", 403);
      }

      changes.accessRights = {
        ...getAccessRights(user),
        ...body.accessRights,
      };
    }

    // ========================================================
    // DATA SCOPE
    // ========================================================

    if ("dataScope" in body) {
      if (!["all", "own", "assigned"].includes(body.dataScope)) {
        return fail("Invalid data scope.");
      }

      // Only Admin may give all-data scope.
      if (body.dataScope === "all" && req.account.role !== "Admin") {
        return fail("Only Admin can assign company-wide data access.", 403);
      }

      changes.dataScope = body.dataScope;
    }

    // ========================================================
    // PASSWORD
    // ========================================================

    if (body.password) {
      if (
        typeof body.password !== "string" ||
        body.password.length < 8 ||
        Buffer.byteLength(body.password) > 72
      ) {
        return fail(
          "Password must be at least 8 characters and at most 72 bytes.",
        );
      }

      changes.password = await bcrypt.hash(body.password, 12);
    }

    // ========================================================
    // PROFILE IMAGE
    // ========================================================

    if (req.file) {
      changes.profileImage = `/uploads/profile/${req.file.filename}`;
    }

    // ========================================================
    // PROTECT CONFIGURED ADMIN
    // ========================================================

    if (isConfiguredAdmin(user.email)) {
      return fail(
        "Configured administrator accounts cannot be modified here.",
        403,
      );
    }

    // ========================================================
    // SAVE
    // ========================================================

    Object.assign(user, changes);

    await user.save();

    const safe = await User.findById(user._id).select(fields).lean();

    return res.json({
      success: true,
      message: "User updated successfully.",
      data: serialize(safe),
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "Email, phone or employee code is already in use.",
      });
    }

    if (error.name === "ValidationError") {
      return res.status(400).json({
        success: false,
        message: "Please check the user details.",
      });
    }

    next(error);
  }
};

// ============================================================
// DELETE USER
// ============================================================

exports.remove = async (req, res, next) => {
  try {
    if (!/^[a-f0-9]{24}$/i.test(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid user ID.",
      });
    }

    const user = await User.findOne({
      _id: req.params.id,
      deletedAt: null,
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found.",
      });
    }

    // HR cannot delete.
    if (req.account.role !== "Admin") {
      return res.status(403).json({
        success: false,
        message: "Only Admin can delete users.",
      });
    }

    if (String(user._id) === String(req.user.id)) {
      return res.status(403).json({
        success: false,
        message: "You cannot delete your own account.",
      });
    }

    if (user.role === "Admin" || isConfiguredAdmin(user.email)) {
      return res.status(403).json({
        success: false,
        message: "Admin accounts cannot be removed.",
      });
    }

    user.deletedAt = new Date();

    user.isActive = false;

    await user.save();

    return res.json({
      success: true,
      message: "User deleted successfully.",
    });
  } catch (error) {
    next(error);
  }
};

// ============================================================
// EXPORT USERS
// ============================================================

exports.export = async (req, res, next) => {
  try {
    if (!["Admin", "HR"].includes(req.account.role)) {
      return res.status(403).json({
        success: false,
        message: "You do not have permission to export users.",
      });
    }

    const search = String(req.query.q || "")
      .trim()
      .toLowerCase();

    let users = await User.find({
      deletedAt: null,
    })
      .select(fields)
      .lean();

    users = users.map(serialize).filter((user) => {
      const values = [
        user.employerCode,
        user.firstName,
        user.lastName,
        user.email,
        user.phone,
        user.role,
      ]
        .join(" ")
        .toLowerCase();

      return values.includes(search);
    });

    function safe(value) {
      if (typeof value === "string" && /^[=+@\-\t\r]/.test(value)) {
        return `'${value}`;
      }

      return value;
    }

    const rows = users.map((user) => ({
      "Employee Code": safe(user.employerCode),

      "First Name": safe(user.firstName),

      "Last Name": safe(user.lastName),

      Email: safe(user.email),

      Phone: safe(user.phone),

      Role: user.role,

      "Data Scope": user.dataScope,

      Status: user.isActive ? "Active" : "Inactive",
    }));

    const book = XLSX.utils.book_new();

    const sheet = XLSX.utils.json_to_sheet(rows);

    XLSX.utils.book_append_sheet(book, sheet, "Users");

    res.setHeader(
      "Content-Type",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    );

    res.setHeader("Content-Disposition", 'attachment; filename="users.xlsx"');

    return res.send(
      XLSX.write(book, {
        type: "buffer",
        bookType: "xlsx",
      }),
    );
  } catch (error) {
    next(error);
  }
};
