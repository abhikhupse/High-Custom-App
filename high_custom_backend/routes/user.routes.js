const express = require("express");
const router = express.Router();

const userCtrl = require("../controller/user.controller");
const { validateRegister } = require("../middleware/validation");
const authMiddleware = require("../middleware/auth.middleware");
const upload = require("../middleware/upload.middleware");

router.post("/register", validateRegister, userCtrl.register);
router.post("/verify-otp", userCtrl.verifyOtp);
router.post("/login", userCtrl.login);
router.get("/profile", authMiddleware, userCtrl.getUserDetails);
router.post("/logout", authMiddleware, userCtrl.logout);
router.put(
  "/edit-profile",
  authMiddleware,
  (req, res, next) => {
    upload.single("profileImage")(req, res, (err) => {
      if (err) {
        console.error("UPLOAD ERROR:", err.message);
        return res.status(400).json({
          success: false,
          message: err.message || "File upload failed",
        });
      }
      next();
    });
  },
  userCtrl.editProfile,
);
module.exports = router;
