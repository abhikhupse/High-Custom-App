const express = require("express");
const auth = require("../middleware/auth.middleware");
const controller = require("../controller/businessLinkSettings.controller");
const router = express.Router();
router.get("/", auth, controller.get);
router.put("/", auth, controller.save);
module.exports = router;
