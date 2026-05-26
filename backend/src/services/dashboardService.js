const pool = require('../db/pool');

/** Conteos compatibles con DashboardStats de Flutter. */
async function getStats(userId) {
  const [animales, raciones, produccion, costos] = await Promise.all([
    pool.query('SELECT COUNT(*)::int AS total FROM animales WHERE usuario_id = $1', [userId]),
    pool.query(
      `SELECT COUNT(*)::int AS total FROM raciones r
       INNER JOIN animales a ON a.id = r.animal_id WHERE a.usuario_id = $1`,
      [userId],
    ),
    pool.query(
      `SELECT COUNT(*)::int AS total FROM registros_produccion rp
       INNER JOIN animales a ON a.id = rp.animal_id WHERE a.usuario_id = $1`,
      [userId],
    ),
    pool.query(
      `SELECT COUNT(*)::int AS total FROM costos_alimentacion c
       INNER JOIN animales a ON a.id = c.animal_id WHERE a.usuario_id = $1`,
      [userId],
    ),
  ]);

  return {
    animales: animales.rows[0].total,
    raciones: raciones.rows[0].total,
    produccion: produccion.rows[0].total,
    costos: costos.rows[0].total,
  };
}

async function getSummary(userId) {
  const stats = await getStats(userId);
  const [produccionSum, costosSum, recomendaciones] = await Promise.all([
    pool.query(
      `SELECT COALESCE(SUM(rp.produccion), 0)::float AS total
       FROM registros_produccion rp
       INNER JOIN animales a ON a.id = rp.animal_id WHERE a.usuario_id = $1`,
      [userId],
    ),
    pool.query(
      `SELECT COALESCE(SUM(c.costo), 0)::float AS total
       FROM costos_alimentacion c
       INNER JOIN animales a ON a.id = c.animal_id WHERE a.usuario_id = $1`,
      [userId],
    ),
    pool.query(
      `SELECT COUNT(*)::int AS total FROM recomendaciones rec
       INNER JOIN animales a ON a.id = rec.animal_id WHERE a.usuario_id = $1`,
      [userId],
    ),
  ]);

  return {
    ...stats,
    produccionTotal: produccionSum.rows[0].total,
    costosTotal: costosSum.rows[0].total,
    totalRecomendaciones: recomendaciones.rows[0].total,
  };
}

async function getProductionOverTime(userId, days = 30) {
  const { rows } = await pool.query(
    `SELECT to_char(rp.fecha, 'YYYY-MM-DD') AS day, SUM(rp.produccion)::float AS total
     FROM registros_produccion rp
     INNER JOIN animales a ON a.id = rp.animal_id
     WHERE a.usuario_id = $1
     GROUP BY day
     ORDER BY day DESC
     LIMIT $2`,
    [userId, days],
  );
  return rows.map((r) => ({ day: r.day, total: r.total })).reverse();
}

async function getCostsVsProduction(userId, days = 30) {
  const { rows } = await pool.query(
    `WITH prod AS (
       SELECT to_char(rp.fecha, 'YYYY-MM-DD') AS day, SUM(rp.produccion)::float AS v
       FROM registros_produccion rp
       INNER JOIN animales a ON a.id = rp.animal_id
       WHERE a.usuario_id = $1
       GROUP BY day
     ),
     cost AS (
       SELECT to_char(c.fecha, 'YYYY-MM-DD') AS day, SUM(c.costo)::float AS v
       FROM costos_alimentacion c
       INNER JOIN animales a ON a.id = c.animal_id
       WHERE a.usuario_id = $1
       GROUP BY day
     )
     SELECT COALESCE(prod.day, cost.day) AS day,
            COALESCE(cost.v, 0)::float AS costo,
            COALESCE(prod.v, 0)::float AS produccion
     FROM prod
     FULL OUTER JOIN cost ON cost.day = prod.day
     ORDER BY day DESC
     LIMIT $2`,
    [userId, days],
  );
  return rows.map((r) => ({
    day: r.day,
    costo: r.costo,
    produccion: r.produccion,
  })).reverse();
}

module.exports = { getStats, getSummary, getProductionOverTime, getCostsVsProduction };
