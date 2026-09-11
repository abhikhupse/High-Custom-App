const express = require("express");
const auth = require("../middleware/auth.middleware");
const requireAdmin = require("../middleware/admin.middleware");
const controller = require("../controller/admin_dashboard.controller");

const router = express.Router();
router.get("/dashboard", auth, requireAdmin, controller.getDashboard);
const users = require('../controller/admin_users.controller');
const upload = require('../middleware/upload.middleware');
router.get('/users-export', auth, requireAdmin, users.export);
router.get('/users', auth, requireAdmin, users.list);
router.patch('/users/:id', auth, requireAdmin, upload.single('profileImage'), users.update);
router.delete('/users/:id', auth, requireAdmin, users.remove);
module.exports = router;
