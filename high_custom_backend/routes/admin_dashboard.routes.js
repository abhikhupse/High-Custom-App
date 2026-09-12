const express = require("express");

const auth = require("../middleware/auth.middleware");

const requireAdmin = require("../middleware/admin.middleware");
const {
  requireAppRight,
  requireAccessRight,
} = require("../middleware/user-access");

const { allowAdminOrRoles } = require("../middleware/role.middleware");

const dashboardController = require("../controller/admin_dashboard.controller");
const emailTrackingController = require("../controller/email_tracking.controller");
const adminWorkspaceController = require("../controller/admin_workspace.controller");

const users = require("../controller/admin_users.controller");

const upload = require("../middleware/upload.middleware");

const router = express.Router();

// ============================================================
// ADMIN DASHBOARD
// ============================================================

// Keep true Admin dashboard restricted to Admin.
router.get(
  "/dashboard",
  auth,
  requireAdmin,
  requireAppRight("dashboard"),
  requireAccessRight("viewDashboard"),
  dashboardController.getDashboard,
);
router.get(
  "/tracking-report",
  auth,
  requireAdmin,
  requireAppRight("trackingReport"),
  requireAccessRight("viewTrackingReport"),
  emailTrackingController.getAdminTrackingReport,
);

// Company-wide operational lists. These intentionally remain separate from
// the normal user routes so a user cannot gain access by changing a query.
router.get(
  "/leads",
  auth,
  requireAdmin,
  requireAppRight("leads"),
  requireAccessRight("viewAllUsersLeads"),
  adminWorkspaceController.listLeads,
);
router.get(
  "/sequences",
  auth,
  requireAdmin,
  requireAppRight("sequences"),
  requireAccessRight("viewAllUsersSequences"),
  adminWorkspaceController.listSequences,
);
router.patch(
  "/sequences/:sequenceId",
  auth,
  requireAdmin,
  requireAppRight("sequences"),
  requireAccessRight("editSequence"),
  adminWorkspaceController.updateSequence,
);
router.delete(
  "/sequences/:sequenceId",
  auth,
  requireAdmin,
  requireAppRight("interestedLeads"),
  requireAccessRight("deleteInterestedLead"),
  requireAccessRight("deleteSequence"),
  adminWorkspaceController.deleteSequence,
);
router.get(
  "/interested-leads",
  auth,
  requireAdmin,
  requireAppRight("interestedLeads"),
  requireAccessRight("viewAllInterestedLeads"),
  adminWorkspaceController.listInterestedLeads,
);
router.delete(
  "/interested-leads/:interestId",
  auth,
  requireAdmin,
  adminWorkspaceController.deleteInterestedLead,
);

// ============================================================
// USERS
// Admin + HR can see users.
// ============================================================

router.get(
  "/users",
  auth,
  allowAdminOrRoles("Admin", "HR"),
  requireAppRight("users"),
  requireAccessRight("viewUsers"),
  users.list,
);
router.post(
  "/users",
  auth,
  requireAdmin,
  requireAppRight("users"),
  requireAccessRight("createEmployee"),
  upload.single("profileImage"),
  users.create,
);
router.post(
  "/users/roles",
  auth,
  requireAdmin,
  requireAppRight("users"),
  requireAccessRight("manageHR"),
  users.createRole,
);
router.post(
  "/users/copy-rights",
  auth,
  requireAdmin,
  requireAppRight("users"),
  requireAccessRight("manageEmployeeAccessRights"),
  users.copyRights,
);

// ============================================================
// EXPORT USERS
// ============================================================

router.get(
  "/users-export",
  auth,
  allowAdminOrRoles("Admin", "HR"),
  requireAppRight("users"),
  requireAccessRight("viewUsers"),
  users.export,
);

// ============================================================
// UPDATE USER
// Admin -> HR + Employee
// HR    -> Employee only
// Controller enforces hierarchy.
// ============================================================

router.patch(
  "/users/:id",
  auth,
  allowAdminOrRoles("Admin", "HR"),
  requireAppRight("users"),
  requireAccessRight("editEmployee"),
  upload.single("profileImage"),
  users.update,
);

// ============================================================
// DELETE USER
// ADMIN ONLY
// ============================================================

router.delete(
  "/users/:id",
  auth,
  requireAdmin,
  requireAppRight("users"),
  requireAccessRight("deleteEmployee"),
  users.remove,
);

module.exports = router;
