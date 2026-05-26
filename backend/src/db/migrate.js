const pool = require('./pool');
const { SCHEMA } = require('./schema');
const logger = require('../utils/logger');

async function migrate() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(SCHEMA);

    const migrationName = 'schema_v2';
    const existing = await client.query(
      'SELECT name FROM migrations WHERE name = $1',
      [migrationName],
    );
    if (existing.rows.length === 0) {
      await client.query('INSERT INTO migrations (name) VALUES ($1)', [migrationName]);
      logger.info(`Migración ${migrationName} aplicada`);
    } else {
      logger.info('Esquema ya migrado');
    }

    await client.query('COMMIT');
    logger.info('Migraciones completadas');
  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Error en migración', { error: err.message });
    throw err;
  } finally {
    client.release();
    if (require.main === module) {
      await pool.end();
    }
  }
}

if (require.main === module) {
  migrate().catch(() => process.exit(1));
}

module.exports = migrate;
