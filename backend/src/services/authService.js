const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const env = require('../config/env');
const usuariosService = require('./usuariosService');
const AppError = require('../utils/AppError');

function signToken(user) {
  return jwt.sign({ email: user.email }, env.jwt.secret, {
    subject: String(user.id),
    expiresIn: env.jwt.expiresIn,
  });
}

async function login(email, password) {
  const user = await usuariosService.findByEmail(email);
  if (!user) {
    throw new AppError('Credenciales inválidas', 401, 'INVALID_CREDENTIALS');
  }
  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) {
    throw new AppError('Credenciales inválidas', 401, 'INVALID_CREDENTIALS');
  }
  const token = signToken(user);
  return {
    token,
    user: { id: user.id, nombre: user.nombre, email: user.email },
  };
}

async function register({ nombre, email, password }) {
  const existing = await usuariosService.findByEmail(email);
  if (existing) {
    throw new AppError('El email ya está registrado', 409, 'EMAIL_EXISTS');
  }
  const passwordHash = await bcrypt.hash(password, 12);
  const user = await usuariosService.create({ nombre, email, passwordHash });
  const token = signToken(user);
  return { token, user };
}

async function me(userId) {
  const user = await usuariosService.findById(userId);
  if (!user) throw new AppError('Usuario no encontrado', 404, 'NOT_FOUND');
  return user;
}

module.exports = { login, register, me };
