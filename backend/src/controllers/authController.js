const { body } = require('express-validator');
const authService = require('../services/authService');
const validateRequest = require('../middleware/validate');

async function login(req, res, next) {
  try {
    const result = await authService.login(req.body.email, req.body.password);
    res.json(result);
  } catch (err) {
    next(err);
  }
}

async function register(req, res, next) {
  try {
    const result = await authService.register(req.body);
    res.status(201).json(result);
  } catch (err) {
    next(err);
  }
}

async function me(req, res, next) {
  try {
    const user = await authService.me(req.user.id);
    res.json(user);
  } catch (err) {
    next(err);
  }
}

const loginValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Email inválido'),
  body('password').isLength({ min: 4 }).withMessage('Contraseña mínima 4 caracteres'),
  validateRequest,
];

const registerValidation = [
  body('nombre').trim().isLength({ min: 2 }).escape(),
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 4 }),
  validateRequest,
];

module.exports = { login, register, me, loginValidation, registerValidation };
