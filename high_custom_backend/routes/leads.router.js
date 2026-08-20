const express = require("express");
const multer = require("multer");

const router = express.Router();

const leadsCtrl = require("../controller/leads.controller");

const authMiddleware = require("../middleware/auth.middleware");

// ============================================================
// MULTER
// ============================================================

const upload = multer({
  storage: multer.memoryStorage(),

  limits: {
    fileSize: 10 * 1024 * 1024,
  },

  fileFilter: (req, file, cb) => {
    const allowedExtensions = [".xlsx", ".xls"];

    const extension = file.originalname
      .toLowerCase()
      .substring(file.originalname.lastIndexOf("."));

    if (!allowedExtensions.includes(extension)) {
      return cb(new Error("Only Excel files (.xlsx, .xls) are allowed."));
    }

    cb(null, true);
  },
});

// ============================================================
// GET LEADS
// ============================================================

router.get("/get-leads", authMiddleware, leadsCtrl.getLeads);

// ============================================================
// CREATE LEAD
// ============================================================

router.post("/create-lead", authMiddleware, leadsCtrl.createLead);

// ============================================================
// IMPORT EXCEL
// ============================================================

router.post(
  "/import-excel",
  authMiddleware,
  upload.single("file"),
  leadsCtrl.importLeadsFromExcel,
);

// ============================================================
// EXPORT EXCEL
// ============================================================

router.get("/export-excel", authMiddleware, leadsCtrl.exportLeadsToExcel);

// ============================================================
// UPDATE LEAD
// ============================================================

router.put("/update-lead/:leadId", authMiddleware, leadsCtrl.editLead);

// ============================================================
// DELETE LEAD
// ============================================================

router.delete("/delete-lead/:leadId", authMiddleware, leadsCtrl.deleteLead);

module.exports = router;
