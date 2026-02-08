const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const db = require("../config/db");
require("dotenv").config();

// Registrar novo usuário
exports.register = async (req, res) => {
  try {
    const { username, email, password, full_name } = req.body;

    // Validações básicas
    if (!username || !email || !password) {
      return res.status(400).json({
        success: false,
        message: "Username, email e password são obrigatórios",
      });
    }

    // Verificar se usuário já existe
    const [existingUser] = await db.query(
      "SELECT * FROM users WHERE username = ? OR email = ?",
      [username, email],
    );

    if (existingUser.length > 0) {
      return res.status(409).json({
        success: false,
        message: "Username ou email já cadastrado",
      });
    }

    // Hash da senha
    const saltRounds = 10;
    const password_hash = await bcrypt.hash(password, saltRounds);

    // Inserir usuário no banco
    const [result] = await db.query(
      "INSERT INTO users (username, email, password_hash, full_name) VALUES (?, ?, ?, ?)",
      [username, email, password_hash, full_name || null],
    );

    // Gerar token JWT
    const token = jwt.sign(
      {
        userId: result.insertId,
        username,
        email,
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN },
    );

    res.status(201).json({
      success: true,
      message: "Usuário registrado com sucesso",
      data: {
        userId: result.insertId,
        username,
        email,
        token,
      },
    });
  } catch (error) {
    console.error("Erro no registro:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao registrar usuário",
      error: error.message,
    });
  }
};

// Login de usuário
exports.login = async (req, res) => {
  try {
    const { username, password } = req.body;

    // Validações
    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: "Username e password são obrigatórios",
      });
    }

    // Buscar usuário
    const [users] = await db.query(
      "SELECT * FROM users WHERE username = ? OR email = ?",
      [username, username],
    );

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: "Credenciais inválidas",
      });
    }

    const user = users[0];

    // Verificar se usuário está ativo
    if (!user.is_active) {
      return res.status(403).json({
        success: false,
        message: "Conta desativada",
      });
    }

    // Comparar senha
    const passwordMatch = await bcrypt.compare(password, user.password_hash);

    if (!passwordMatch) {
      return res.status(401).json({
        success: false,
        message: "Credenciais inválidas",
      });
    }

    // Gerar token JWT
    const token = jwt.sign(
      {
        userId: user.user_id,
        username: user.username,
        email: user.email,
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN },
    );

    res.status(200).json({
      success: true,
      message: "Login realizado com sucesso",
      data: {
        userId: user.user_id,
        username: user.username,
        email: user.email,
        fullName: user.full_name,
        profilePicture: user.profile_picture,
        subscriptionType: user.subscription_type,
        token,
      },
    });
  } catch (error) {
    console.error("Erro no login:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao fazer login",
      error: error.message,
    });
  }
};

// Obter perfil do usuário (rota protegida)
exports.getProfile = async (req, res) => {
  try {
    const userId = req.user.userId;

    const [users] = await db.query(
      "SELECT user_id, username, email, full_name, profile_picture, subscription_type, created_at FROM users WHERE user_id = ?",
      [userId],
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Usuário não encontrado",
      });
    }

    res.status(200).json({
      success: true,
      data: users[0],
    });
  } catch (error) {
    console.error("Erro ao buscar perfil:", error);
    res.status(500).json({
      success: false,
      message: "Erro ao buscar perfil",
      error: error.message,
    });
  }
};
