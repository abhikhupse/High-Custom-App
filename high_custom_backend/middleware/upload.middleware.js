const multer = require("multer");
const path = require("path");
const fs = require("fs");

function uploadError(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

// ============================================================
// UPLOAD DIRECTORIES
// ============================================================

const uploadDirectories = {
  brand: path.join(__dirname, "../uploads/brand"),
  hero: path.join(__dirname, "../uploads/hero"),
  attachments: path.join(__dirname, "../uploads/attachments"),
  profile: path.join(__dirname, "../uploads/profile"),
};

// Create directories if they don't exist
Object.values(uploadDirectories).forEach((directory) => {
  if (!fs.existsSync(directory)) {
    fs.mkdirSync(directory, {
      recursive: true,
    });
  }
});

// ============================================================
// STORAGE
// ============================================================

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    if (file.fieldname === "brandLogo") {
      cb(null, uploadDirectories.brand);
    } else if (file.fieldname === "heroImage") {
      cb(null, uploadDirectories.hero);
    } else if (file.fieldname === "attachment") {
      cb(null, uploadDirectories.attachments);
    } else if (file.fieldname === "profileImage") {
      cb(null, uploadDirectories.profile);
    } else {
      cb(uploadError("Invalid upload field"));
    }
  },

  filename: function (req, file, cb) {
    const uniqueName =
      Date.now() +
      "-" +
      Math.round(Math.random() * 1e9) +
      path.extname(file.originalname);

    cb(null, uniqueName);
  },
});

// ============================================================
// FILE FILTER
// ============================================================

const fileFilter = (req, file, cb) => {
  // ----------------------------------------------------------
  // BRAND LOGO
  // ----------------------------------------------------------

  if (file.fieldname === "brandLogo") {
    const allowedImages = [
      "image/jpeg",
      "image/jpg",
      "image/png",
      "image/webp",
    ];

    if (!allowedImages.includes(file.mimetype)) {
      return cb(uploadError("Brand logo must be JPG, JPEG, PNG or WEBP"), false);
    }

    return cb(null, true);
  }

  // Profile Image

  if (file.fieldname === "profileImage") {
    const allowedImages = [
      "image/jpeg",
      "image/jpg",
      "image/png",
      "image/webp",
    ];

    if (!allowedImages.includes(file.mimetype)) {
      return cb(
        uploadError("Profile image must be JPG, JPEG, PNG or WEBP"),
        false,
      );
    }

    return cb(null, true);
  }
  // ----------------------------------------------------------
  // HERO IMAGE
  // ----------------------------------------------------------

  if (file.fieldname === "heroImage") {
    const allowedImages = [
      "image/jpeg",
      "image/jpg",
      "image/png",
      "image/webp",
    ];

    if (!allowedImages.includes(file.mimetype)) {
      return cb(uploadError("Hero image must be JPG, JPEG, PNG or WEBP"), false);
    }

    return cb(null, true);
  }

  // ----------------------------------------------------------
  // ATTACHMENT
  // ----------------------------------------------------------

  if (file.fieldname === "attachment") {
    const allowedFiles = [
      // PDF
      "application/pdf",

      // Word
      "application/msword",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",

      // Excel
      "application/vnd.ms-excel",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",

      // PowerPoint
      "application/vnd.ms-powerpoint",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation",

      // Text
      "text/plain",

      // ZIP
      "application/zip",
      "application/x-zip-compressed",
    ];

    if (!allowedFiles.includes(file.mimetype)) {
      return cb(uploadError("Invalid attachment file type"), false);
    }

    return cb(null, true);
  }

  return cb(uploadError("Unexpected file field"), false);
};

// ============================================================
// MULTER CONFIGURATION
// ============================================================

const upload = multer({
  storage,

  fileFilter,

  limits: {
    // Maximum single file size = 10 MB
    fileSize: 10 * 1024 * 1024,

    // Maximum number of files
    files: 3,
  },
});

module.exports = upload;
