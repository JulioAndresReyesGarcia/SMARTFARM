const express = require('express');
const authController = require('../controllers/authController');
const authenticate = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimiter');

const router = express.Router();

router.post('/login', authLimiter, authController.loginValidation, authController.login);
router.post('/register', authLimiter, authController.registerValidation, authController.register);
router.get('/me', authenticate, authController.me);

module.exports = router;
