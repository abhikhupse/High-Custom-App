const express = require("express");
const auth = require("../middleware/auth.middleware");
const controller = require("../controller/device_token.controller");

const router = express.Router();
router.post("/", auth, controller.register);
module.exports = router;
