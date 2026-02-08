const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");
const authMiddleware = require("../middleware/authMiddleware");

// Rotas públicas
router.post("/register", authController.register);
router.post("/login", authController.login);

// Rotas protegidas (requer autenticação)
router.get("/profile", authMiddleware, authController.getProfile);

module.exports = router;
