const jwt = require('jsonwebtoken');
const env = require('../config/env');
const AppError = require('../utils/AppError');

/** Middleware: verifica JWT Bearer y adjunta req.user */
function authenticate(req, _res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return next(new AppError('Token requerido', 401, 'UNAUTHORIZED'));
  }

  const token = header.slice(7);
  try {
    const payload = jwt.verify(token, env.jwt.secret);
    req.user = { id: payload.sub, email: payload.email };
    next();
  } catch {
    next(new AppError('Token inválido o expirado', 401, 'UNAUTHORIZED'));
  }
}

module.exports = authenticate;
