const express = require('express');
const dashboardService = require('../services/dashboardService');
const authenticate = require('../middleware/auth');
const { query } = require('express-validator');
const validateRequest = require('../middleware/validate');

const router = express.Router();

const daysQuery = [
  query('days').optional().isInt({ min: 1, max: 365 }),
  validateRequest,
];

router.get('/stats', authenticate, async (req, res, next) => {
  try {
    const stats = await dashboardService.getStats(req.user.id);
    res.json(stats);
  } catch (err) {
    next(err);
  }
});

router.get('/summary', authenticate, async (req, res, next) => {
  try {
    const summary = await dashboardService.getSummary(req.user.id);
    res.json(summary);
  } catch (err) {
    next(err);
  }
});

router.get('/production-over-time', authenticate, daysQuery, async (req, res, next) => {
  try {
    const days = parseInt(req.query.days || '30', 10);
    const data = await dashboardService.getProductionOverTime(req.user.id, days);
    res.json(data);
  } catch (err) {
    next(err);
  }
});

router.get('/costs-vs-production', authenticate, daysQuery, async (req, res, next) => {
  try {
    const days = parseInt(req.query.days || '30', 10);
    const data = await dashboardService.getCostsVsProduction(req.user.id, days);
    res.json(data);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
