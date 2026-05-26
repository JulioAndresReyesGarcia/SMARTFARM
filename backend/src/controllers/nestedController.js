const { body, param } = require('express-validator');
const racionesService = require('../services/racionesService');
const recomendacionesService = require('../services/recomendacionesService');
const produccionService = require('../services/produccionService');
const costosService = require('../services/costosService');
const validateRequest = require('../middleware/validate');

const animalIdParam = [
  param('animalId').isInt({ min: 1 }),
  validateRequest,
];

const nestedIdParam = [
  param('animalId').isInt({ min: 1 }),
  param('id').isInt({ min: 1 }),
  validateRequest,
];

async function listRaciones(req, res, next) {
  try {
    const data = await racionesService.list(Number(req.params.animalId), req.user.id);
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function createRacion(req, res, next) {
  try {
    const data = await racionesService.create(Number(req.params.animalId), req.user.id, req.body);
    res.status(201).json(data);
  } catch (err) {
    next(err);
  }
}

async function deleteRacion(req, res, next) {
  try {
    await racionesService.remove(Number(req.params.id), Number(req.params.animalId), req.user.id);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

async function updateRacion(req, res, next) {
  try {
    const data = await racionesService.update(
      Number(req.params.id),
      Number(req.params.animalId),
      req.user.id,
      req.body,
    );
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function listRecomendaciones(req, res, next) {
  try {
    const data = await recomendacionesService.list(Number(req.params.animalId), req.user.id);
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function createRecomendacion(req, res, next) {
  try {
    const data = await recomendacionesService.create(Number(req.params.animalId), req.user.id, req.body);
    res.status(201).json(data);
  } catch (err) {
    next(err);
  }
}

async function deleteRecomendacion(req, res, next) {
  try {
    await recomendacionesService.remove(Number(req.params.id), Number(req.params.animalId), req.user.id);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

async function updateRecomendacion(req, res, next) {
  try {
    const data = await recomendacionesService.update(
      Number(req.params.id),
      Number(req.params.animalId),
      req.user.id,
      req.body,
    );
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function listProduccion(req, res, next) {
  try {
    const data = await produccionService.list(Number(req.params.animalId), req.user.id);
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function createProduccion(req, res, next) {
  try {
    const data = await produccionService.create(Number(req.params.animalId), req.user.id, req.body);
    res.status(201).json(data);
  } catch (err) {
    next(err);
  }
}

async function deleteProduccion(req, res, next) {
  try {
    await produccionService.remove(Number(req.params.id), Number(req.params.animalId), req.user.id);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

async function updateProduccion(req, res, next) {
  try {
    const data = await produccionService.update(
      Number(req.params.id),
      Number(req.params.animalId),
      req.user.id,
      req.body,
    );
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function listCostos(req, res, next) {
  try {
    const data = await costosService.list(Number(req.params.animalId), req.user.id);
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function createCosto(req, res, next) {
  try {
    const data = await costosService.create(Number(req.params.animalId), req.user.id, req.body);
    res.status(201).json(data);
  } catch (err) {
    next(err);
  }
}

async function deleteCosto(req, res, next) {
  try {
    await costosService.remove(Number(req.params.id), Number(req.params.animalId), req.user.id);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

async function updateCosto(req, res, next) {
  try {
    const data = await costosService.update(
      Number(req.params.id),
      Number(req.params.animalId),
      req.user.id,
      req.body,
    );
    res.json(data);
  } catch (err) {
    next(err);
  }
}

const racionValidation = [
  body('fecha').isISO8601(),
  body('cantidad').isFloat({ min: 0 }),
  body('tipo_alimento').trim().isLength({ min: 1 }).escape(),
  validateRequest,
];

const racionUpdateValidation = [
  body('cantidad').isFloat({ min: 0 }),
  body('tipo_alimento').trim().isLength({ min: 1 }).escape(),
  validateRequest,
];

const recomendacionValidation = [
  body('recomendacion').trim().isLength({ min: 1 }).escape(),
  body('fecha').isISO8601(),
  validateRequest,
];

const recomendacionUpdateValidation = [
  body('recomendacion').trim().isLength({ min: 1 }).escape(),
  validateRequest,
];

const produccionValidation = [
  body('fecha').isISO8601(),
  body('produccion').isFloat({ min: 0 }),
  validateRequest,
];

const produccionUpdateValidation = [
  body('produccion').isFloat({ min: 0 }),
  validateRequest,
];

const costoValidation = [
  body('fecha').isISO8601(),
  body('costo').isFloat({ min: 0 }),
  validateRequest,
];

const costoUpdateValidation = [
  body('costo').isFloat({ min: 0 }),
  validateRequest,
];

module.exports = {
  animalIdParam,
  nestedIdParam,
  listRaciones,
  createRacion: [animalIdParam, ...racionValidation, createRacion],
  updateRacion: [nestedIdParam, ...racionUpdateValidation, updateRacion],
  deleteRacion: [nestedIdParam, deleteRacion],
  listRecomendaciones,
  createRecomendacion: [animalIdParam, ...recomendacionValidation, createRecomendacion],
  updateRecomendacion: [nestedIdParam, ...recomendacionUpdateValidation, updateRecomendacion],
  deleteRecomendacion: [nestedIdParam, deleteRecomendacion],
  listProduccion,
  createProduccion: [animalIdParam, ...produccionValidation, createProduccion],
  updateProduccion: [nestedIdParam, ...produccionUpdateValidation, updateProduccion],
  deleteProduccion: [nestedIdParam, deleteProduccion],
  listCostos,
  createCosto: [animalIdParam, ...costoValidation, createCosto],
  updateCosto: [nestedIdParam, ...costoUpdateValidation, updateCosto],
  deleteCosto: [nestedIdParam, deleteCosto],
};
