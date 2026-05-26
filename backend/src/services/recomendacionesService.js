const pool = require('../db/pool');
const { assertAnimalOwnership } = require('./animalesService');
const AppError = require('../utils/AppError');

async function list(animalId, userId) {
  await assertAnimalOwnership(animalId, userId);
  const { rows } = await pool.query(
    `SELECT id, animal_id, recomendacion, fecha
     FROM recomendaciones WHERE animal_id = $1 ORDER BY fecha DESC`,
    [animalId],
  );
  return rows.map((r) => ({ ...r, fecha: r.fecha.toISOString() }));
}

async function create(animalId, userId, data) {
  await assertAnimalOwnership(animalId, userId);
  const { rows } = await pool.query(
    `INSERT INTO recomendaciones (animal_id, recomendacion, fecha)
     VALUES ($1, $2, $3)
     RETURNING id, animal_id, recomendacion, fecha`,
    [animalId, data.recomendacion.trim(), data.fecha],
  );
  const row = rows[0];
  return { ...row, fecha: row.fecha.toISOString() };
}

async function update(id, animalId, userId, data) {
  await assertAnimalOwnership(animalId, userId);
  const { rows } = await pool.query(
    `UPDATE recomendaciones SET recomendacion = $1, updated_at = NOW()
     WHERE id = $2 AND animal_id = $3
     RETURNING id, animal_id, recomendacion, fecha`,
    [data.recomendacion.trim(), id, animalId],
  );
  if (rows.length === 0) throw new AppError('Recomendación no encontrada', 404, 'NOT_FOUND');
  const row = rows[0];
  return { ...row, fecha: row.fecha.toISOString() };
}

async function remove(id, animalId, userId) {
  await assertAnimalOwnership(animalId, userId);
  const { rowCount } = await pool.query(
    'DELETE FROM recomendaciones WHERE id = $1 AND animal_id = $2',
    [id, animalId],
  );
  if (rowCount === 0) throw new AppError('Recomendación no encontrada', 404, 'NOT_FOUND');
}

module.exports = { list, create, update, remove };
