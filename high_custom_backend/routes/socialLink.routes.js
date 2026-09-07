const express = require("express");
const auth = require("../middleware/auth.middleware");
const controller = require("../controller/socialLink.controller");

const router = express.Router();

router.get("/r/:id", controller.redirect);
router.get("/", auth, controller.list);
router.post("/", auth, controller.create);
router.patch("/:id", auth, controller.update);
router.delete("/:id", auth, controller.remove);
router.post("/generate-qr", auth, controller.generateQr);
router.get("/qr", auth, controller.listQr);
router.delete("/:id/qr", auth, controller.deleteQr);

module.exports = router;
