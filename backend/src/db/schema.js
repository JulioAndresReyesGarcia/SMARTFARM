/**
 * Esquema PostgreSQL alineado con SQLite local (lib/database/app_database.dart).
 * usuario_id en animales permite aislamiento multi-usuario en modo distribuido.
 */
const SCHEMA = `
CREATE TABLE IF NOT EXISTS migrations (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL UNIQUE,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS usuarios (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS animales (
  id SERIAL PRIMARY KEY,
  usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  nombre VARCHAR(255) NOT NULL,
  peso REAL NOT NULL,
  edad INTEGER NOT NULL,
  tipo VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raciones (
  id SERIAL PRIMARY KEY,
  animal_id INTEGER NOT NULL REFERENCES animales(id) ON DELETE CASCADE,
  fecha TIMESTAMPTZ NOT NULL,
  cantidad REAL NOT NULL,
  tipo_alimento VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS recomendaciones (
  id SERIAL PRIMARY KEY,
  animal_id INTEGER NOT NULL REFERENCES animales(id) ON DELETE CASCADE,
  recomendacion TEXT NOT NULL,
  fecha TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS registros_produccion (
  id SERIAL PRIMARY KEY,
  animal_id INTEGER NOT NULL REFERENCES animales(id) ON DELETE CASCADE,
  fecha TIMESTAMPTZ NOT NULL,
  produccion REAL NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS costos_alimentacion (
  id SERIAL PRIMARY KEY,
  animal_id INTEGER NOT NULL REFERENCES animales(id) ON DELETE CASCADE,
  costo REAL NOT NULL,
  fecha TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_animales_usuario ON animales(usuario_id);
CREATE INDEX IF NOT EXISTS idx_animales_tipo ON animales(tipo);
CREATE INDEX IF NOT EXISTS idx_raciones_animal_fecha ON raciones(animal_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_recomendaciones_animal_fecha ON recomendaciones(animal_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_produccion_animal_fecha ON registros_produccion(animal_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_costos_animal_fecha ON costos_alimentacion(animal_id, fecha DESC);
`;

module.exports = { SCHEMA };
