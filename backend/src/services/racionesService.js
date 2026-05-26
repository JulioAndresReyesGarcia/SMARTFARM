const pool = require('../db/pool');
const { assertAnimalOwnership } = require('./animalesService');
const AppError = require('../utils/AppError');

async function list(animalId, userId) {
  await assertAnimalOwnership(animalId, userId);
  const { rows } = await pool.query(
    `SELECT id, animal_id, fecha, cantidad, tipo_alimento
     FROM raciones WHERE animal_id = $1 ORDER BY fecha DESC`,
    [animalId],
  );
  return rows.map((r) => ({ ...r, fecha: r.fecha.toISOString() }));
}

async function create(animalId, userId, data) {
  await assertAnimalOwnership(animalId, userId);
  const { rows } = await pool.query(
    `INSERT INTO raciones (animal_id, fecha, cantidad, tipo_alimento)
     VALUES ($1, $2, $3, $4)
     RETURNING id, animal_id, fecha, cantidad, tipo_alimento`,
    [animalId, data.fecha, data.cantidad, data.tipo_alimento.trim()],
  );
  const row = rows[0];
  return { ...row, fecha: row.fecha.toISOString() };
}

async function update(id, animalId, userId, data) {
  await assertAnimalOwnership(animalId, userId);
  const { rows } = await pool.query(
    `UPDATE raciones SET cantidad = $1, tipo_alimento = $2, updated_at = NOW()
     WHERE id = $3 AND animal_id = $4
     RETURNING id, animal_id, fecha, cantidad, tipo_alimento`,
    [data.cantidad, data.tipo_alimento.trim(), id, animalId],
  );
  if (rows.length === 0) throw new AppError('Ración no encontrada', 404, 'NOT_FOUND');
  const row = rows[0];
  return { ...row, fecha: row.fecha.toISOString() };
}

async function remove(id, animalId, userId) {
  await assertAnimalOwnership(animalId, userId);
  const { rowCount } = await pool.query(
    'DELETE FROM raciones WHERE id = $1 AND animal_id = $2',
    [id, animalId],
  );
  if (rowCount === 0) throw new AppError('Ración no encontrada', 404, 'NOT_FOUND');
}

module.exports = { list, create, update, remove };
