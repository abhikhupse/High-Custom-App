const express = require("express");
const router = express.Router();
const User = require("./user.routes");
const Sequence = require("./sequence.routes");
const Leads = require("./leads.router");
const Integration = require("./gmail_integration.routes");

router.use("/user", User);
router.use("/sequence", Sequence);
router.use("/leads", Leads);
router.use("/integrations", Integration);

module.exports = router;
