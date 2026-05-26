const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const env = require('./config/env');
const logger = require('./utils/logger');
const migrate = require('./db/migrate');
const seed = require('./db/seed');
const { globalLimiter } = require('./middleware/rateLimiter');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

const authRoutes = require('./routes/auth.routes');
const animalesRoutes = require('./routes/animales.routes');
const dashboardRoutes = require('./routes/dashboard.routes');
const iaRoutes = require('./routes/ia.routes');

async function bootstrap() {
  await migrate();

  const app = express();

  // Seguridad HTTP básica (OWASP)
  app.use(helmet());
  app.use(
    cors({
      origin: env.corsOrigin === '*' ? true : env.corsOrigin.split(','),
      credentials: true,
    }),
  );
  app.use(express.json({ limit: '1mb' }));
  app.use(globalLimiter);

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', service: 'smartfarm-api', env: env.nodeEnv });
  });

  app.use('/api/auth', authRoutes);
  app.use('/api/animales', animalesRoutes);
  app.use('/api/dashboard', dashboardRoutes);
  app.use('/api/ia', iaRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  app.listen(env.port, async () => {
    try {
      await seed();
    } catch (err) {
      logger.warn('Seed omitido o fallido (puede requerir BD lista)', { error: err.message });
    }
    logger.info(`SmartFarm API escuchando en puerto ${env.port}`);
  });
}

bootstrap().catch((err) => {
  logger.error('Fallo al iniciar servidor', { error: err.message });
  process.exit(1);
});
