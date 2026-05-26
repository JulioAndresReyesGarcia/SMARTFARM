const { body, param, query } = require('express-validator');
const animalesService = require('../services/animalesService');
const validateRequest = require('../middleware/validate');

async function list(req, res, next) {
  try {
    const tipo = req.query.tipo;
    const data = await animalesService.listByUser(req.user.id, tipo);
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const animal = await animalesService.getById(Number(req.params.id), req.user.id);
    if (!animal) return res.status(404).json({ error: 'Animal no encontrado', code: 'NOT_FOUND' });
    res.json(animal);
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const animal = await animalesService.create(req.user.id, req.body);
    res.status(201).json(animal);
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const animal = await animalesService.update(Number(req.params.id), req.user.id, req.body);
    res.json(animal);
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    await animalesService.remove(Number(req.params.id), req.user.id);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

const animalBodyValidation = [
  body('nombre').trim().isLength({ min: 1 }).escape(),
  body('peso').isFloat({ min: 0 }),
  body('edad').isInt({ min: 0 }),
  body('tipo').trim().isLength({ min: 1 }).escape(),
  validateRequest,
];

const idParam = [param('id').isInt({ min: 1 }), validateRequest];
const tipoQuery = [query('tipo').optional().trim().escape(), validateRequest];

module.exports = {
  list,
  getById,
  create,
  update,
  remove,
  animalBodyValidation,
  idParam,
  tipoQuery,
};
