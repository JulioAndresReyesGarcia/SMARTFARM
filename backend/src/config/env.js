require('dotenv').config();

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    database: process.env.DB_NAME || 'smartfarm',
    user: process.env.DB_USER || 'smartfarm',
    password: process.env.DB_PASSWORD || 'smartfarm_secret',
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'dev_only_change_in_production',
    expiresIn: process.env.JWT_EXPIRES_IN || '24h',
  },
  corsOrigin: process.env.CORS_ORIGIN || '*',
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10),
    max: parseInt(process.env.RATE_LIMIT_MAX || '200', 10),
  },
  demo: {
    email: process.env.DEMO_ADMIN_EMAIL || 'admin@smartfarm.ai',
    password: process.env.DEMO_ADMIN_PASSWORD || '1234',
  },
};

if (env.nodeEnv === 'production' && env.jwt.secret === 'dev_only_change_in_production') {
  console.warn('[WARN] JWT_SECRET no configurado para producción');
}

module.exports = env;
