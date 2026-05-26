const express = require('express');
const { body } = require('express-validator');
const iaService = require('../services/iaService');
const animalesService = require('../services/animalesService');
const recomendacionesService = require('../services/recomendacionesService');
const authenticate = require('../middleware/auth');
const validateRequest = require('../middleware/validate');

const router = express.Router();

router.post(
  '/chat',
  authenticate,
  [
    body('animalId').isInt({ min: 1 }),
    body('message').trim().notEmpty().isLength({ max: 2000 }),
    body('history').optional().isArray({ max: 20 }),
    body('history.*.role').optional().isIn(['user', 'assistant']),
    body('history.*.content').optional().trim().isLength({ max: 2000 }),
    validateRequest,
  ],
  async (req, res, next) => {
    try {
      const animalId = Number(req.body.animalId);
      const animal = await animalesService.getById(animalId, req.user.id);
      if (!animal) {
        return res.status(404).json({ error: 'Animal no encontrado', code: 'NOT_FOUND' });
      }

      const result = await iaService.chat({
        animal,
        message: req.body.message,
        history: req.body.history,
      });

      res.json(result);
    } catch (err) {
      next(err);
    }
  },
);

router.post(
  '/recomendaciones',
  authenticate,
  [
    body('animalId').isInt({ min: 1 }),
    body('context').optional().trim().escape(),
    validateRequest,
  ],
  async (req, res, next) => {
    try {
      const animalId = Number(req.body.animalId);
      const animal = await animalesService.getById(animalId, req.user.id);
      if (!animal) {
        return res.status(404).json({ error: 'Animal no encontrado', code: 'NOT_FOUND' });
      }

      const generated = await iaService.generateRecommendation({
        animal,
        context: req.body.context,
      });

      const saved = await recomendacionesService.create(animalId, req.user.id, {
        recomendacion: generated.recomendacion,
        fecha: generated.fecha,
      });

      res.status(201).json({ ...saved, source: generated.source });
    } catch (err) {
      next(err);
    }
  },
);

module.exports = router;
