const pool = require('../db/pool');
const AppError = require('../utils/AppError');

/** Verifica que el animal pertenezca al usuario autenticado. */
async function assertAnimalOwnership(animalId, userId) {
  const { rows } = await pool.query(
    'SELECT id FROM animales WHERE id = $1 AND usuario_id = $2',
    [animalId, userId],
  );
  if (rows.length === 0) {
    throw new AppError('Animal no encontrado', 404, 'NOT_FOUND');
  }
}

async function listByUser(userId, tipo) {
  const params = [userId];
  let sql = 'SELECT id, nombre, peso, edad, tipo FROM animales WHERE usuario_id = $1';
  if (tipo) {
    params.push(tipo.trim());
    sql += ` AND tipo = $${params.length}`;
  }
  sql += ' ORDER BY id DESC';
  const { rows } = await pool.query(sql, params);
  return rows;
}

async function getById(id, userId) {
  const { rows } = await pool.query(
    'SELECT id, nombre, peso, edad, tipo FROM animales WHERE id = $1 AND usuario_id = $2',
    [id, userId],
  );
  return rows[0] || null;
}

async function create(userId, data) {
  const { rows } = await pool.query(
    `INSERT INTO animales (usuario_id, nombre, peso, edad, tipo)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, nombre, peso, edad, tipo`,
    [userId, data.nombre.trim(), data.peso, data.edad, data.tipo.trim()],
  );
  return rows[0];
}

async function update(id, userId, data) {
  const { rows } = await pool.query(
    `UPDATE animales SET nombre = $1, peso = $2, edad = $3, tipo = $4, updated_at = NOW()
     WHERE id = $5 AND usuario_id = $6
     RETURNING id, nombre, peso, edad, tipo`,
    [data.nombre.trim(), data.peso, data.edad, data.tipo.trim(), id, userId],
  );
  if (rows.length === 0) throw new AppError('Animal no encontrado', 404, 'NOT_FOUND');
  return rows[0];
}

async function remove(id, userId) {
  const { rowCount } = await pool.query(
    'DELETE FROM animales WHERE id = $1 AND usuario_id = $2',
    [id, userId],
  );
  if (rowCount === 0) throw new AppError('Animal no encontrado', 404, 'NOT_FOUND');
}

module.exports = {
  assertAnimalOwnership,
  listByUser,
  getById,
  create,
  update,
  remove,
};
