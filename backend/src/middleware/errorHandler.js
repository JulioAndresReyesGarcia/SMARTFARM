const logger = require('../utils/logger');
const AppError = require('../utils/AppError');

/** Middleware centralizado de errores (OWASP: no filtrar stack en producción). */
function errorHandler(err, req, res, _next) {
  const status = err.statusCode || 500;
  const code = err.code || 'INTERNAL_ERROR';

  if (status >= 500) {
    logger.error(err.message, {
      stack: err.stack,
      path: req.path,
      method: req.method,
    });
  } else {
    logger.warn(err.message, { path: req.path, code });
  }

  res.status(status).json({
    error: err.message || 'Error interno del servidor',
    code,
    ...(process.env.NODE_ENV !== 'production' && err.stack ? { stack: err.stack } : {}),
  });
}

/** 404 para rutas no registradas */
function notFoundHandler(req, _res, next) {
  next(new AppError(`Ruta no encontrada: ${req.method} ${req.path}`, 404, 'NOT_FOUND'));
}

module.exports = { errorHandler, notFoundHandler };
