const express = require("express");

const router = express.Router();

const leadsCtrl = require("../controller/leads.controller");

const authMiddleware = require("../middleware/auth.middleware");

// ============================================================
// GET ALL LEADS
// ============================================================

router.get("/get-leads", authMiddleware, leadsCtrl.getLeads);

// ============================================================
// CREATE LEAD
// ============================================================

router.post("/create-lead", authMiddleware, leadsCtrl.createLead);

// ============================================================
// UPDATE LEAD
// ============================================================

router.put("/update-lead/:leadId", authMiddleware, leadsCtrl.editLead);

// ============================================================
// DELETE LEAD
// ============================================================

router.delete("/delete-lead/:leadId", authMiddleware, leadsCtrl.deleteLead);

module.exports = router;
