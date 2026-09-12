// ============================================================
// ROLE PERMISSIONS
// ============================================================

const ADMIN_APP_RIGHTS = {
  dashboard: true,
  users: true,
  leads: true,
  interestedLeads: true,
  sequences: true,
  trackingReport: true,
  socialLinks: true,
  businessLink: true,
  integrations: true,
  notifications: true,
  profile: true,
  appRightsManagement: true,
  accessRightsManagement: true,
};

const HR_APP_RIGHTS = {
  dashboard: true,
  users: true,
  leads: true,
  interestedLeads: true,
  sequences: true,
  trackingReport: true,
  socialLinks: true,
  businessLink: true,

  // HR cannot control integrations.
  integrations: false,

  notifications: true,
  profile: true,

  // HR can manage employee access actions, not app/module availability.
  appRightsManagement: false,
  accessRightsManagement: true,
};

const EMPLOYEE_APP_RIGHTS = {
  dashboard: true,

  users: false,

  leads: true,
  interestedLeads: true,
  sequences: true,
  trackingReport: true,
  socialLinks: true,
  businessLink: true,
  integrations: true,
  notifications: true,
  profile: true,

  appRightsManagement: false,
  accessRightsManagement: false,
};

// ============================================================
// ADMIN ACCESS RIGHTS
// ============================================================

const ADMIN_ACCESS_RIGHTS = {
  viewDashboard: true,
  viewCompanyDashboard: true,

  viewUsers: true,
  viewUserDetails: true,
  createEmployee: true,
  editEmployee: true,
  deleteEmployee: true,
  activateDeactivateEmployee: true,
  changeEmployeeRole: true,
  manageHR: true,
  manageAdmin: true,

  viewLeads: true,
  viewAllUsersLeads: true,
  createLead: true,
  editLead: true,
  deleteLead: true,
  importLeads: true,
  exportLeads: true,

  viewInterestedLeads: true,
  viewAllInterestedLeads: true,
  editInterestedLead: true,
  deleteInterestedLead: true,
  exportInterestedLeads: true,

  viewSequences: true,
  viewAllUsersSequences: true,
  createSequence: true,
  editSequence: true,
  deleteSequence: true,
  runSequence: true,

  viewTrackingReport: true,
  viewAllUsersTracking: true,
  exportTrackingReport: true,

  viewSocialLinks: true,
  createSocialLink: true,
  editSocialLink: true,
  deleteSocialLink: true,

  viewBusinessLink: true,
  createBusinessLink: true,
  editBusinessLink: true,
  deleteBusinessLink: true,

  viewIntegrations: true,
  connectIntegration: true,
  disconnectIntegration: true,

  viewNotifications: true,
  markNotificationRead: true,
  deleteNotification: true,

  viewProfile: true,
  editProfile: true,

  manageEmployeeAppRights: false,
  manageEmployeeAccessRights: true,
  manageHRAppRights: true,
  manageHRAccessRights: true,
};

// ============================================================
// HR ACCESS RIGHTS
// ============================================================

const HR_ACCESS_RIGHTS = {
  viewDashboard: true,
  viewCompanyDashboard: true,

  viewUsers: true,
  viewUserDetails: true,

  createEmployee: true,
  editEmployee: true,

  // HR cannot permanently delete people by default.
  deleteEmployee: false,

  activateDeactivateEmployee: true,

  // Cannot promote Employee -> Admin / HR without Admin.
  changeEmployeeRole: false,

  manageHR: false,
  manageAdmin: false,

  // ========================================================
  // LEADS
  // ========================================================

  viewLeads: true,

  // HR can see every user's leads.
  viewAllUsersLeads: true,

  createLead: true,
  editLead: true,

  deleteLead: false,

  importLeads: true,
  exportLeads: true,

  // ========================================================
  // INTERESTED LEADS
  // ========================================================

  viewInterestedLeads: true,
  viewAllInterestedLeads: true,
  editInterestedLead: true,
  deleteInterestedLead: false,
  exportInterestedLeads: true,

  // ========================================================
  // SEQUENCES
  // ========================================================

  viewSequences: true,

  // HR can inspect all users' sequences.
  viewAllUsersSequences: true,

  createSequence: true,
  editSequence: true,

  deleteSequence: false,

  runSequence: true,

  // ========================================================
  // TRACKING
  // ========================================================

  viewTrackingReport: true,
  viewAllUsersTracking: true,
  exportTrackingReport: true,

  // ========================================================
  // SOCIAL / BUSINESS LINK
  // ========================================================

  viewSocialLinks: true,
  createSocialLink: true,
  editSocialLink: true,
  deleteSocialLink: false,

  viewBusinessLink: true,
  createBusinessLink: true,
  editBusinessLink: true,
  deleteBusinessLink: false,

  // ========================================================
  // INTEGRATIONS
  // ========================================================

  // You selected HR limited access.
  viewIntegrations: false,
  connectIntegration: false,
  disconnectIntegration: false,

  // ========================================================
  // NOTIFICATIONS
  // ========================================================

  viewNotifications: true,
  markNotificationRead: true,
  deleteNotification: true,

  // ========================================================
  // PROFILE
  // ========================================================

  viewProfile: true,
  editProfile: true,

  // ========================================================
  // PERMISSIONS
  // ========================================================

  // HR can modify Employee permissions.
  manageEmployeeAppRights: true,
  manageEmployeeAccessRights: true,

  // HR cannot modify HR/Admin permissions.
  manageHRAppRights: false,
  manageHRAccessRights: false,
};

// ============================================================
// EMPLOYEE ACCESS RIGHTS
// ============================================================

const EMPLOYEE_ACCESS_RIGHTS = {
  viewDashboard: true,
  viewCompanyDashboard: false,

  viewUsers: false,
  viewUserDetails: false,

  createEmployee: false,
  editEmployee: false,
  deleteEmployee: false,
  activateDeactivateEmployee: false,
  changeEmployeeRole: false,

  manageHR: false,
  manageAdmin: false,

  // ========================================================
  // LEADS
  // ========================================================

  viewLeads: true,

  // Own / assigned only.
  viewAllUsersLeads: false,

  createLead: true,
  editLead: true,
  deleteLead: false,

  importLeads: false,
  exportLeads: false,

  // ========================================================
  // INTERESTED LEADS
  // ========================================================

  viewInterestedLeads: true,
  viewAllInterestedLeads: false,
  editInterestedLead: true,
  deleteInterestedLead: false,
  exportInterestedLeads: false,

  // ========================================================
  // SEQUENCES
  // ========================================================

  viewSequences: true,
  viewAllUsersSequences: false,

  createSequence: true,
  editSequence: true,
  deleteSequence: false,
  runSequence: true,

  // ========================================================
  // TRACKING
  // ========================================================

  viewTrackingReport: true,
  viewAllUsersTracking: false,
  exportTrackingReport: false,

  // ========================================================
  // SOCIAL LINKS
  // ========================================================

  viewSocialLinks: true,
  createSocialLink: true,
  editSocialLink: true,
  deleteSocialLink: false,

  // ========================================================
  // BUSINESS LINK
  // ========================================================

  viewBusinessLink: true,
  createBusinessLink: true,
  editBusinessLink: true,
  deleteBusinessLink: false,

  // ========================================================
  // INTEGRATIONS
  // ========================================================

  // Own connected account.
  viewIntegrations: true,
  connectIntegration: true,
  disconnectIntegration: true,

  // ========================================================
  // NOTIFICATIONS
  // ========================================================

  viewNotifications: true,
  markNotificationRead: true,
  deleteNotification: true,

  // ========================================================
  // PROFILE
  // ========================================================

  viewProfile: true,
  editProfile: true,

  // ========================================================
  // RIGHTS
  // ========================================================

  manageEmployeeAppRights: false,
  manageEmployeeAccessRights: false,
  manageHRAppRights: false,
  manageHRAccessRights: false,
};

// ============================================================
// ROLE CONFIG
// ============================================================

const ROLE_CONFIG = {
  Admin: {
    dataScope: "all",
    appRights: ADMIN_APP_RIGHTS,
    accessRights: ADMIN_ACCESS_RIGHTS,
  },

  HR: {
    // HR works with employees across the company, without receiving the
    // unrestricted system-wide Admin scope.
    dataScope: "company",
    appRights: HR_APP_RIGHTS,
    accessRights: HR_ACCESS_RIGHTS,
  },

  Employee: {
    dataScope: "own",
    appRights: EMPLOYEE_APP_RIGHTS,
    accessRights: EMPLOYEE_ACCESS_RIGHTS,
  },
};

function getRolePermissions(role = "Employee") {
  return ROLE_CONFIG[role] || ROLE_CONFIG.Employee;
}

module.exports = {
  ROLE_CONFIG,
  getRolePermissions,

  ADMIN_APP_RIGHTS,
  HR_APP_RIGHTS,
  EMPLOYEE_APP_RIGHTS,

  ADMIN_ACCESS_RIGHTS,
  HR_ACCESS_RIGHTS,
  EMPLOYEE_ACCESS_RIGHTS,
};
