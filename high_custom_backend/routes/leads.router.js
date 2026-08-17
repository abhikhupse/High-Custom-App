const express = require("express");
const router = express.Router();
const leadsCtrl = require("../controller/leads.controller");
const authMiddleware = require("../middleware/auth.middleware");

router.post("/create-lead", authMiddleware, leadsCtrl.createLead);
router.put("/update-lead/:leadId", authMiddleware, leadsCtrl.editLead);

module.exports = router;
