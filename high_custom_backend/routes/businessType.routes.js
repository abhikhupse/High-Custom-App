const express = require("express");
const authMiddleware = require("../middleware/auth.middleware");
const businessTypeController = require("../controller/businessType.controller");

const router = express.Router();

router.get("/", authMiddleware, businessTypeController.listBusinessTypes);
router.post("/", authMiddleware, businessTypeController.createBusinessType);
router.patch("/:id", authMiddleware, businessTypeController.updateBusinessType);
router.delete("/:id", authMiddleware, businessTypeController.deleteBusinessType);

module.exports = router;
