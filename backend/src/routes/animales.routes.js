const express = require('express');
const animalesController = require('../controllers/animalesController');
const nested = require('../controllers/nestedController');
const authenticate = require('../middleware/auth');

const router = express.Router();

router.use(authenticate);

router.get('/', animalesController.tipoQuery, animalesController.list);
router.post('/', animalesController.animalBodyValidation, animalesController.create);

// Rutas anidadas (antes de /:id para evitar colisiones)
router.get('/:animalId/raciones', nested.listRaciones);
router.post('/:animalId/raciones', nested.createRacion);
router.put('/:animalId/raciones/:id', nested.updateRacion);
router.delete('/:animalId/raciones/:id', nested.deleteRacion);

router.get('/:animalId/recomendaciones', nested.listRecomendaciones);
router.post('/:animalId/recomendaciones', nested.createRecomendacion);
router.put('/:animalId/recomendaciones/:id', nested.updateRecomendacion);
router.delete('/:animalId/recomendaciones/:id', nested.deleteRecomendacion);

router.get('/:animalId/produccion', nested.listProduccion);
router.post('/:animalId/produccion', nested.createProduccion);
router.put('/:animalId/produccion/:id', nested.updateProduccion);
router.delete('/:animalId/produccion/:id', nested.deleteProduccion);

router.get('/:animalId/costos', nested.listCostos);
router.post('/:animalId/costos', nested.createCosto);
router.put('/:animalId/costos/:id', nested.updateCosto);
router.delete('/:animalId/costos/:id', nested.deleteCosto);

router.get('/:id', animalesController.idParam, animalesController.getById);
router.put('/:id', [...animalesController.idParam, ...animalesController.animalBodyValidation], animalesController.update);
router.delete('/:id', animalesController.idParam, animalesController.remove);

module.exports = router;
