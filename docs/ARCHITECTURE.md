# Arquitectura distribuida SmartFarm AI

Este documento describe la arquitectura cliente-servidor del proyecto, pensada para un entorno universitario: moderna, segura y escalable, sin eliminar el modo offline local.

## Visión general

SmartFarm opera en **dos modos compatibles**:

| Modo | Persistencia | Autenticación | Uso |
|------|--------------|---------------|-----|
| **Local** (default) | SQLite en el dispositivo | Credenciales en BD local | Demo, offline, desarrollo UI |
| **Remoto** | PostgreSQL vía API REST | JWT + bcrypt en backend | Arquitectura distribuida, multi-cliente |

### Capa de sync (Flutter)

```
AnimalesService (facade) → AnimalesRepository → AnimalesLocalDataSource | AnimalesApiService
```

Misma estructura para raciones, producción, costos, recomendaciones, dashboard y analytics. La UI y los providers **no cambian**; el modo se activa con `--dart-define=USE_REMOTE_BACKEND=true`.

flowchart TB
  subgraph Cliente["Cliente Android (Flutter)"]
    UI[Pantallas / Providers]
    REPO[AuthRepository / Servicios]
    SQLITE[(SQLite local)]
    API_CLIENT[ApiClient HTTP]
    UI --> REPO
    REPO -->|modo local| SQLITE
    REPO -->|modo remoto| API_CLIENT
  end

  subgraph Backend["Backend Node.js + Express"]
    MW[Middleware: auth, rate limit, helmet]
    ROUTES[Rutas REST /api/*]
    SVC[Servicios de dominio]
    IA[Servicio IA proxy]
    MW --> ROUTES --> SVC
    ROUTES --> IA
  end

  subgraph Data["Capa de datos"]
    PG[(PostgreSQL)]
  end

  API_CLIENT -->|HTTPS / REST + JWT| MW
  SVC --> PG
  IA -->|OpenAI API| EXT[Proveedor IA externo]
```

## Capas y responsabilidades

### 1. Cliente Android (Flutter)
- **UI + Provider**: sin cambios de flujo para el usuario final.
- **`AppConfig`**: activa modo remoto con `--dart-define`.
- **`AuthRepository`**: delega login a SQLite o API según configuración.
- **SQLite**: sigue siendo la fuente de verdad en modo local.

### 2. Backend API (`backend/`)
- **Express** con arquitectura en capas: routes → controllers → services → PostgreSQL.
- **JWT** para sesiones stateless.
- **bcrypt** para hash de contraseñas (nunca plaintext en servidor).
- **express-validator** + consultas parametrizadas (prevención SQL injection / XSS básico).

### 3. Middleware
| Middleware | Función |
|------------|---------|
| `helmet` | Cabeceras HTTP seguras |
| `cors` | Control de orígenes |
| `rateLimiter` | Límite global y en `/auth` |
| `authenticate` | Validación JWT |
| `validateRequest` | Validación de entrada |
| `errorHandler` | Respuestas de error uniformes |

### 4. Base de datos
- **SQLite**: app móvil (offline-first).
- **PostgreSQL**: backend escalable, esquema alineado con SQLite + `usuario_id` en animales para aislamiento multi-usuario.

### 5. Servicio IA
- Proxy en backend (`/api/ia/recomendaciones`) para no exponer `OPENAI_API_KEY` al cliente.
- Fallback con reglas locales si no hay clave configurada.

### 6. Contenedores y Kubernetes
- **Docker Compose**: PostgreSQL + API para desarrollo/demo.
- **Kubernetes** (`k8s/smartfarm.yaml`): Deployment, Service, ConfigMap, Secret, namespace `smartfarm`.

## Endpoints API

Base URL: `http://localhost:3000` (host) o `http://10.0.2.2:3000` (emulador Android).

### Salud
| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/health` | No | Estado del servicio |

### Autenticación
| Método | Ruta | Auth | Body |
|--------|------|------|------|
| POST | `/api/auth/login` | No | `{ email, password }` |
| POST | `/api/auth/register` | No | `{ nombre, email, password }` |
| GET | `/api/auth/me` | JWT | — |

### Animales
| Método | Ruta | Auth |
|--------|------|------|
| GET | `/api/animales?tipo=` | JWT |
| GET | `/api/animales/:id` | JWT |
| POST | `/api/animales` | JWT |
| PUT | `/api/animales/:id` | JWT |
| DELETE | `/api/animales/:id` | JWT |

### Recursos anidados (por animal)
- `GET/POST/PUT/DELETE /api/animales/:animalId/raciones` — PUT: `{ cantidad, tipo_alimento }`
- `GET/POST/PUT/DELETE /api/animales/:animalId/recomendaciones` — PUT: `{ recomendacion }`
- `GET/POST/PUT/DELETE /api/animales/:animalId/produccion` — PUT: `{ produccion }`
- `GET/POST/PUT/DELETE /api/animales/:animalId/costos` — PUT: `{ costo }`

### Dashboard e IA
| Método | Ruta | Auth |
|--------|------|------|
| GET | `/api/dashboard/summary` | JWT |
| POST | `/api/ia/recomendaciones` | JWT |

## Variables de entorno (backend)

Ver `backend/.env.example`. Principales:

| Variable | Descripción |
|----------|-------------|
| `PORT` | Puerto HTTP (default 3000) |
| `DB_*` | Conexión PostgreSQL |
| `JWT_SECRET` | Secreto para firmar tokens |
| `JWT_EXPIRES_IN` | Expiración del token |
| `CORS_ORIGIN` | Orígenes permitidos |
| `OPENAI_API_KEY` | Clave IA (opcional, solo servidor) |
| `DEMO_ADMIN_*` | Usuario seed inicial |

## Ejecución

### Backend con Docker Compose (recomendado)
```bash
docker compose up --build
curl http://localhost:3000/health
```

### Backend local (sin Docker)
```bash
cd backend
cp .env.example .env
npm install
npm run migrate
npm run seed
npm run dev
```

### App Flutter — modo local (sin cambios)
```bash
flutter pub get
flutter run
```

### App Flutter — modo remoto
```bash
flutter run --dart-define=USE_REMOTE_BACKEND=true --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Credenciales demo (ambos modos): `admin@smartfarm.ai` / `1234`

## Kubernetes (universidad / demo)

```bash
kubectl apply -f k8s/smartfarm.yaml
kubectl get pods -n smartfarm
```

Componentes:
- **ConfigMap** `smartfarm-api-config`: variables no sensibles.
- **Secret** `smartfarm-api-secrets`: contraseñas y JWT.
- **Deployment** `smartfarm-api`: 2 réplicas con probes `/health`.
- **Service** `smartfarm-api`: ClusterIP puerto 80 → 3000.
- **Deployment** `smartfarm-postgres`: PostgreSQL con volumen efímero (demo).

> En producción real usar PersistentVolumeClaim, Ingress con TLS y secretos gestionados (Vault, Sealed Secrets, etc.).

## Seguridad (OWASP básico)

- Contraseñas hasheadas con bcrypt (cost 12).
- JWT con expiración configurable.
- Rate limiting en auth y global.
- Validación y escape de entradas.
- Consultas SQL parametrizadas (`$1`, `$2`…).
- Helmet para cabeceras HTTP.
- Secretos en `.env` / Kubernetes Secret, nunca en código.
- HTTPS recomendado detrás de reverse proxy o Ingress TLS.

## Evolución futura (sin romper lo existente)

1. Repositorios Flutter para animales/raciones con sync bidireccional.
2. Cola de mensajes (RabbitMQ/Redis) para eventos de sensores.
3. Microservicio IA independiente.
4. Refresh tokens y almacenamiento seguro de JWT en dispositivo.
