const express = require("express");

const auth = require("../middleware/auth.middleware");

const requireAdmin = require("../middleware/admin.middleware");

const { allowRoles } = require("../middleware/role.middleware");

const dashboardController = require("../controller/admin_dashboard.controller");

const users = require("../controller/admin_users.controller");

const upload = require("../middleware/upload.middleware");

const router = express.Router();

// ============================================================
// ADMIN DASHBOARD
// ============================================================

// Keep true Admin dashboard restricted to Admin.
router.get("/dashboard", auth, requireAdmin, dashboardController.getDashboard);

// ============================================================
// USERS
// Admin + HR can see users.
// ============================================================

router.get("/users", auth, allowRoles("Admin", "HR"), users.list);

// ============================================================
// EXPORT USERS
// ============================================================

router.get("/users-export", auth, allowRoles("Admin", "HR"), users.export);

// ============================================================
// UPDATE USER
// Admin -> HR + Employee
// HR    -> Employee only
// Controller enforces hierarchy.
// ============================================================

router.patch(
  "/users/:id",
  auth,
  allowRoles("Admin", "HR"),
  upload.single("profileImage"),
  users.update,
);

// ============================================================
// DELETE USER
// ADMIN ONLY
// ============================================================

router.delete("/users/:id", auth, requireAdmin, users.remove);

module.exports = router;
