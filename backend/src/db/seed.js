const bcrypt = require('bcryptjs');
const pool = require('./pool');
const env = require('../config/env');
const logger = require('../utils/logger');

async function seed() {
  const hash = await bcrypt.hash(env.demo.password, 12);
  const result = await pool.query(
    `INSERT INTO usuarios (email, password_hash, nombre)
     VALUES ($1, $2, $3)
     ON CONFLICT (email) DO UPDATE SET
       password_hash = EXCLUDED.password_hash,
       updated_at = NOW()
     RETURNING id, email, nombre`,
    [env.demo.email, hash, 'Administrador Demo'],
  );
  logger.info('Usuario demo listo', { email: result.rows[0].email });
  if (require.main === module) {
    await pool.end();
  }
}

if (require.main === module) {
  seed().catch((err) => {
    logger.error('Error en seed', { error: err.message });
    process.exit(1);
  });
}

module.exports = seed;
