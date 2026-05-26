const pool = require('../db/pool');
const AppError = require('../utils/AppError');

async function findByEmail(email) {
  const { rows } = await pool.query(
    'SELECT id, nombre, email, password_hash FROM usuarios WHERE email = $1',
    [email.toLowerCase().trim()],
  );
  return rows[0] || null;
}

async function findById(id) {
  const { rows } = await pool.query(
    'SELECT id, nombre, email FROM usuarios WHERE id = $1',
    [id],
  );
  return rows[0] || null;
}

async function create({ nombre, email, passwordHash }) {
  const { rows } = await pool.query(
    `INSERT INTO usuarios (nombre, email, password_hash)
     VALUES ($1, $2, $3)
     RETURNING id, nombre, email`,
    [nombre.trim(), email.toLowerCase().trim(), passwordHash],
  );
  return rows[0];
}

module.exports = { findByEmail, findById, create };
