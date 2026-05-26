const { validationResult } = require('express-validator');
const AppError = require('../utils/AppError');

/** Valida resultados de express-validator y lanza 400 si hay errores. */
function validateRequest(req, _res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return next(
      new AppError('Datos de entrada inválidos', 400, 'VALIDATION_ERROR'),
    );
  }
  next();
}

module.exports = validateRequest;
