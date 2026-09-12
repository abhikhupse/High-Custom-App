const mongoose = require("mongoose");

// ============================================================
// APP RIGHTS
// ============================================================

const appRightsSchema = new mongoose.Schema(
  {
    dashboard: {
      type: Boolean,
      default: true,
    },

    users: {
      type: Boolean,
      default: false,
    },

    leads: {
      type: Boolean,
      default: true,
    },

    interestedLeads: {
      type: Boolean,
      default: true,
    },

    sequences: {
      type: Boolean,
      default: true,
    },

    trackingReport: {
      type: Boolean,
      default: true,
    },

    socialLinks: {
      type: Boolean,
      default: true,
    },

    businessLink: {
      type: Boolean,
      default: true,
    },

    integrations: {
      type: Boolean,
      default: true,
    },

    notifications: {
      type: Boolean,
      default: true,
    },

    profile: {
      type: Boolean,
      default: true,
    },

    appRightsManagement: {
      type: Boolean,
      default: false,
    },

    accessRightsManagement: {
      type: Boolean,
      default: false,
    },
  },
  {
    _id: false,
  },
);

// ============================================================
// ACCESS RIGHTS
// ============================================================

const accessRightsSchema = new mongoose.Schema(
  {
    // ========================================================
    // DASHBOARD
    // ========================================================

    viewDashboard: {
      type: Boolean,
      default: true,
    },

    viewCompanyDashboard: {
      type: Boolean,
      default: false,
    },

    // ========================================================
    // USERS
    // ========================================================

    viewUsers: {
      type: Boolean,
      default: false,
    },

    viewUserDetails: {
      type: Boolean,
      default: false,
    },

    createEmployee: {
      type: Boolean,
      default: false,
    },

    editEmployee: {
      type: Boolean,
      default: false,
    },

    deleteEmployee: {
      type: Boolean,
      default: false,
    },

    activateDeactivateEmployee: {
      type: Boolean,
      default: false,
    },

    changeEmployeeRole: {
      type: Boolean,
      default: false,
    },

    manageHR: {
      type: Boolean,
      default: false,
    },

    manageAdmin: {
      type: Boolean,
      default: false,
    },

    // ========================================================
    // LEADS
    // ========================================================

    viewLeads: {
      type: Boolean,
      default: true,
    },

    viewAllUsersLeads: {
      type: Boolean,
      default: false,
    },

    createLead: {
      type: Boolean,
      default: true,
    },

    editLead: {
      type: Boolean,
      default: true,
    },

    deleteLead: {
      type: Boolean,
      default: false,
    },

    importLeads: {
      type: Boolean,
      default: false,
    },

    exportLeads: {
      type: Boolean,
      default: false,
    },

    // ========================================================
    // INTERESTED LEADS
    // ========================================================

    viewInterestedLeads: {
      type: Boolean,
      default: true,
    },

    viewAllInterestedLeads: {
      type: Boolean,
      default: false,
    },

    editInterestedLead: {
      type: Boolean,
      default: true,
    },

    deleteInterestedLead: {
      type: Boolean,
      default: false,
    },

    exportInterestedLeads: {
      type: Boolean,
      default: false,
    },

    // ========================================================
    // SEQUENCES
    // ========================================================

    viewSequences: {
      type: Boolean,
      default: true,
    },

    viewAllUsersSequences: {
      type: Boolean,
      default: false,
    },

    createSequence: {
      type: Boolean,
      default: true,
    },

    editSequence: {
      type: Boolean,
      default: true,
    },

    deleteSequence: {
      type: Boolean,
      default: false,
    },

    runSequence: {
      type: Boolean,
      default: true,
    },

    // ========================================================
    // TRACKING REPORT
    // ========================================================

    viewTrackingReport: {
      type: Boolean,
      default: true,
    },

    viewAllUsersTracking: {
      type: Boolean,
      default: false,
    },

    exportTrackingReport: {
      type: Boolean,
      default: false,
    },

    // ========================================================
    // SOCIAL LINKS
    // ========================================================

    viewSocialLinks: {
      type: Boolean,
      default: true,
    },

    createSocialLink: {
      type: Boolean,
      default: true,
    },

    editSocialLink: {
      type: Boolean,
      default: true,
    },

    deleteSocialLink: {
      type: Boolean,
      default: false,
    },

    // ========================================================
    // BUSINESS LINK
    // ========================================================

    viewBusinessLink: {
      type: Boolean,
      default: true,
    },

    createBusinessLink: {
      type: Boolean,
      default: true,
    },

    editBusinessLink: {
      type: Boolean,
      default: true,
    },

    deleteBusinessLink: {
      type: Boolean,
      default: false,
    },

    // ========================================================
    // INTEGRATIONS
    // ========================================================

    viewIntegrations: {
      type: Boolean,
      default: true,
    },

    connectIntegration: {
      type: Boolean,
      default: true,
    },

    disconnectIntegration: {
      type: Boolean,
      default: true,
    },

    // ========================================================
    // NOTIFICATIONS
    // ========================================================

    viewNotifications: {
      type: Boolean,
      default: true,
    },

    markNotificationRead: {
      type: Boolean,
      default: true,
    },

    deleteNotification: {
      type: Boolean,
      default: true,
    },

    // ========================================================
    // PROFILE
    // ========================================================

    viewProfile: {
      type: Boolean,
      default: true,
    },

    editProfile: {
      type: Boolean,
      default: true,
    },

    // ========================================================
    // PERMISSION MANAGEMENT
    // ========================================================

    manageEmployeeAppRights: {
      type: Boolean,
      default: false,
    },

    manageEmployeeAccessRights: {
      type: Boolean,
      default: false,
    },

    manageHRAppRights: {
      type: Boolean,
      default: false,
    },

    manageHRAccessRights: {
      type: Boolean,
      default: false,
    },
  },
  {
    _id: false,
  },
);

// ============================================================
// USER
// ============================================================

const userSchema = new mongoose.Schema(
  {
    firstName: {
      type: String,
      required: true,
      trim: true,
    },

    lastName: {
      type: String,
      required: true,
      trim: true,
    },

    employerCode: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },

    phone: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },

    profileImage: {
      type: String,
      default: null,
      trim: true,
    },

    password: {
      type: String,
      required: true,
    },

    // ========================================================
    // ROLE
    // ========================================================

    role: {
      type: String,
      // Custom company roles such as Sales are managed by the Administrator.
      default: "Employee",
    },

    // ========================================================
    // DATA SCOPE
    // ========================================================

    dataScope: {
      type: String,
      enum: ["all", "company", "own", "assigned"],
      default: "own",
    },

    // ========================================================
    // STATUS
    // ========================================================

    isActive: {
      type: Boolean,
      default: true,
    },

    deletedAt: {
      type: Date,
      default: null,
    },

    // ========================================================
    // PERMISSIONS
    // ========================================================

    appRights: {
      type: appRightsSchema,
      default: () => ({}),
    },

    accessRights: {
      type: accessRightsSchema,
      default: () => ({}),
    },

    // Keep temporarily so old code does not immediately break.
    accessRight: {
      type: String,
      enum: ["Full Access", "View & Edit", "View Only", "No Access"],
      default: "Full Access",
    },

    // ========================================================
    // EMAIL
    // ========================================================

    isEmailVerified: {
      type: Boolean,
      default: false,
    },

    isLogIn: {
      type: Boolean,
      default: false,
    },

    loginDeviceIps: {
      type: [
        {
          ipAddress: {
            type: String,
            required: true,
            trim: true,
          },

          userAgent: {
            type: String,
            default: "",
          },

          lastSeenAt: {
            type: Date,
            default: Date.now,
          },
        },
      ],

      default: [],
    },

    emailOtp: {
      type: String,
      default: null,
    },

    emailOtpExpires: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  },
);

module.exports = mongoose.model("User", userSchema);
