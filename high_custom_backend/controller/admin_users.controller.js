const bcrypt = require("bcrypt");
const XLSX = require("xlsx");

const User = require("../model/user.model");
const Role = require("../model/role.model");

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

function effectiveAccountRole(account) {
  return isConfiguredAdmin(account?.email) ? "Admin" : account?.role;
}

function normalizeRole(role) {
  // Legacy accounts were stored as "User" before the Employee role was
  // introduced. They must follow Employee permissions in the Admin panel.
  return role === "User" ? "Employee" : role || "Employee";
}

const CORE_ROLES = ["Admin", "HR", "Employee"];

async function isAllowedRole(role) {
  if (CORE_ROLES.includes(role)) return true;
  return Boolean(await Role.exists({ name: role }));
}

// ============================================================
// SERIALIZE
// ============================================================

function serialize(user) {
  const data = user.toObject ? user.toObject() : user;

  const configuredAdmin = isConfiguredAdmin(data.email);

  const effectiveRole = configuredAdmin ? "Admin" : normalizeRole(data.role);

  return {
    ...data,

    role: effectiveRole,

    isAdministrator: effectiveRole === "Admin",

    // This is the configured owner account from ADMIN_EMAILS. It is the only
    // Admin account that cannot be demoted or deactivated from the UI.
    isPrimaryAdministrator: configuredAdmin,

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
    // Admin + HR are allowed. The primary Admin may be configured through
    // ADMIN_EMAILS while their legacy database role is still "User".
    if (
      !["Admin", "HR"].includes(effectiveAccountRole(req.account)) &&
      !isConfiguredAdmin(req.account?.email)
    ) {
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
      // The configured main Admin always stays at the very top of the
      // directory, even when another account also has the Admin role.
      if (a.isPrimaryAdministrator !== b.isPrimaryAdministrator) {
        return a.isPrimaryAdministrator ? -1 : 1;
      }

      const rolePriority = {
        Admin: 3,
        HR: 2,
        Employee: 1,
      };

      const roleDifference = rolePriority[b.role] - rolePriority[a.role];
      if (roleDifference) return roleDifference;

      // Keep the order stable for users with the same role.
      return new Date(b.createdAt || 0) - new Date(a.createdAt || 0);
    });

    const customRoles = await Role.find({})
      .sort({ name: 1 })
      .select("name -_id")
      .lean();

    return res.json({
      success: true,

      currentUserId: String(req.user.id),

      // Normalize legacy primary-admin accounts so the Admin panel enables
      // rights controls even when the database still stores role as "User".
      currentUserRole: normalizeRole(effectiveAccountRole(req.account)),

      roles: [...CORE_ROLES, ...customRoles.map((role) => role.name)],

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

    const body = req.body || {};

    // ========================================================
    // ROLE HIERARCHY
    // ========================================================

    const account = {
      ...req.account,
      role: normalizeRole(effectiveAccountRole(req.account)),
    };

    if (
      !canManageUser(account, {
        ...(user.toObject ? user.toObject() : user),
        role: normalizeRole(user.role),
      })
    ) {
      return res.status(403).json({
        success: false,
        message: "You do not have permission to manage this user.",
      });
    }

    // An Admin created later must never be able to alter the configured main
    // Admin account. The configured Admin can still update their own profile.
    if (
      isConfiguredAdmin(user.email) &&
      !isConfiguredAdmin(req.account?.email)
    ) {
      return res.status(403).json({
        success: false,
        message: "Only the main Administrator can edit this account.",
      });
    }

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

      if (
        isConfiguredAdmin(user.email) &&
        changes.email !== String(user.email).toLowerCase()
      ) {
        return fail(
          "The primary Administrator email cannot be changed here.",
          403,
        );
      }
    }

    // ========================================================
    // STATUS
    // ========================================================

    if ("isActive" in body) {
      if (isConfiguredAdmin(user.email)) {
        return fail("The primary Administrator status cannot be changed.", 403);
      }

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

      if (!(await isAllowedRole(role))) {
        return fail("Invalid role.");
      }

      // HR cannot change roles.
      if (account.role === "HR" && role !== "Employee") {
        return fail("HR can only manage Employee accounts.", 403);
      }

      // Only Admin can assign HR.
      if (role === "HR" && account.role !== "Admin") {
        return fail("Only Admin can assign HR role.", 403);
      }

      // The configured primary Admin must always remain an Admin. Other
      // administrators can be promoted or demoted by an Administrator.
      if (isConfiguredAdmin(user.email) && role !== "Admin") {
        return fail("The primary Administrator role cannot be changed.", 403);
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
      if (account.role === "HR" && normalizeRole(user.role) !== "Employee") {
        return fail("HR can change permissions for Employees only.", 403);
      }

      if (account.role === "HR") {
        return fail(
          "HR cannot manage App Rights. Use Access Rights for Employees.",
          403,
        );
      }

      changes.appRights = {
        ...getAppRights({
          ...(user.toObject ? user.toObject() : user),
          role: normalizeRole(effectiveAccountRole(user)),
        }),
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

      if (account.role === "HR" && normalizeRole(user.role) !== "Employee") {
        return fail("HR can change permissions for Employees only.", 403);
      }

      changes.accessRights = {
        ...getAccessRights({
          ...(user.toObject ? user.toObject() : user),
          role: normalizeRole(effectiveAccountRole(user)),
        }),
        ...body.accessRights,
      };
    }

    // ========================================================
    // DATA SCOPE
    // ========================================================

    if ("dataScope" in body) {
      if (!["all", "company", "own", "assigned"].includes(body.dataScope)) {
        return fail("Invalid data scope.");
      }

      // Only Admin may give all-data scope.
      if (
        ["all", "company"].includes(body.dataScope) &&
        account.role !== "Admin"
      ) {
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
// CREATE USER (ADMIN ONLY)
// ============================================================

exports.create = async (req, res, next) => {
  try {
    const body = req.body || {};
    const firstName = String(body.firstName || "").trim();
    const lastName = String(body.lastName || "").trim();
    const employerCode = String(body.employerCode || "").trim();
    const email = String(body.email || "")
      .trim()
      .toLowerCase();
    const phone = String(body.phone || "").trim();
    const password = String(body.password || "");
    const role = String(body.role || "Employee").trim() || "Employee";

    if (!(await isAllowedRole(role))) {
      return res
        .status(400)
        .json({ success: false, message: "Choose a valid role." });
    }

    if (
      !firstName ||
      !lastName ||
      !employerCode ||
      !email ||
      !phone ||
      password.length < 8
    ) {
      return res.status(400).json({
        success: false,
        message: "Enter all details and a password of at least 8 characters.",
      });
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return res
        .status(400)
        .json({ success: false, message: "Please enter a valid email." });
    }

    const defaults = getRolePermissions(role);
    const user = await User.create({
      firstName,
      lastName,
      employerCode,
      email,
      phone,
      password: await bcrypt.hash(password, 12),
      role,
      dataScope: defaults.dataScope,
      appRights: defaults.appRights,
      accessRights: defaults.accessRights,
      isEmailVerified: true,
      ...(req.file && {
        profileImage: `/uploads/profile/${req.file.filename}`,
      }),
    });
    return res.status(201).json({
      success: true,
      message: "User created successfully.",
      data: serialize(user),
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "Email, phone or employee code is already in use.",
      });
    }
    if (error.name === "ValidationError") {
      return res
        .status(400)
        .json({ success: false, message: "Please check the user details." });
    }
    next(error);
  }
};

// ============================================================
// ADD CUSTOM ROLE (MAIN ADMINISTRATOR ONLY)
// ============================================================

exports.createRole = async (req, res, next) => {
  try {
    if (!isConfiguredAdmin(req.account?.email)) {
      return res.status(403).json({
        success: false,
        message: "Only the main Administrator can add roles.",
      });
    }

    const name = String(req.body?.name || "")
      .trim()
      .replace(/\s+/g, " ");
    if (!/^[A-Za-z0-9 &_-]{2,49}$/.test(name)) {
      return res.status(400).json({
        success: false,
        message: "Role name must be 2–49 letters, numbers, spaces, & _ or -.",
      });
    }
    if (CORE_ROLES.some((role) => role.toLowerCase() === name.toLowerCase())) {
      return res
        .status(400)
        .json({ success: false, message: "This is already a built-in role." });
    }
    if (
      await Role.exists({
        name: new RegExp(
          `^${name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`,
          "i",
        ),
      })
    ) {
      return res
        .status(409)
        .json({ success: false, message: "This role already exists." });
    }

    const role = await Role.create({ name, createdBy: req.user.id });
    return res.status(201).json({
      success: true,
      message: "New role added.",
      data: { name: role.name },
    });
  } catch (error) {
    next(error);
  }
};

// ============================================================
// COPY RIGHTS (ADMIN ONLY)
// ============================================================

exports.copyRights = async (req, res, next) => {
  try {
    const {
      sourceUserId,
      targetType,
      targetUserId,
      targetRole,
      copyAppRights,
      copyAccessRights,
    } = req.body || {};

    if (!sourceUserId || !["user", "role"].includes(targetType)) {
      return res.status(400).json({
        success: false,
        message: "Choose a source and a copy destination.",
      });
    }
    if (!copyAppRights && !copyAccessRights) {
      return res.status(400).json({
        success: false,
        message: "Select App Rights, Access Rights, or both.",
      });
    }

    const source = await User.findOne({
      _id: sourceUserId,
      deletedAt: null,
    }).lean();
    if (!source) {
      return res
        .status(404)
        .json({ success: false, message: "Source user was not found." });
    }

    // A Sub Admin cannot use the main Administrator's rights as a template.
    if (
      isConfiguredAdmin(source.email) &&
      !isConfiguredAdmin(req.account?.email)
    ) {
      return res.status(403).json({
        success: false,
        message: "Only the main Administrator can copy these rights.",
      });
    }

    let targetQuery = { deletedAt: null };
    if (targetType === "user") {
      if (!targetUserId) {
        return res.status(400).json({
          success: false,
          message: "Choose a user to receive the copied rights.",
        });
      }
      targetQuery._id = targetUserId;
    } else {
      if (!targetRole) {
        return res.status(400).json({
          success: false,
          message: "Choose a role to receive the copied rights.",
        });
      }
      // Legacy "User" accounts are displayed as Employees in the Admin UI.
      targetQuery.role =
        targetRole === "Employee" ? { $in: ["Employee", "User"] } : targetRole;
    }

    const targets = await User.find(targetQuery).select("_id email").lean();
    const safeTargets = targets.filter(
      (target) => !isConfiguredAdmin(target.email),
    );
    if (!safeTargets.length) {
      return res.status(400).json({
        success: false,
        message: "No editable users were found for this destination.",
      });
    }

    const changes = {};
    if (copyAppRights) {
      changes.appRights = getAppRights({
        ...source,
        role: normalizeRole(effectiveAccountRole(source)),
      });
    }
    if (copyAccessRights) {
      changes.accessRights = getAccessRights({
        ...source,
        role: normalizeRole(effectiveAccountRole(source)),
      });
      changes.dataScope =
        source.dataScope ||
        getRolePermissions(normalizeRole(effectiveAccountRole(source)))
          .dataScope;
    }

    await User.updateMany(
      { _id: { $in: safeTargets.map((target) => target._id) } },
      { $set: changes },
    );

    return res.json({
      success: true,
      message: `Rights copied to ${safeTargets.length} user${safeTargets.length === 1 ? "" : "s"}.`,
      updatedCount: safeTargets.length,
    });
  } catch (error) {
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
    if (effectiveAccountRole(req.account) !== "Admin") {
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
    if (
      !["Admin", "HR"].includes(
        normalizeRole(effectiveAccountRole(req.account)),
      )
    ) {
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
