# SmartFarm AI

Aplicación Flutter para gestión ganadera con **arquitectura distribuida** (cliente Android + API REST + PostgreSQL), manteniendo compatibilidad **offline-first** con SQLite local.

## Descripción

SmartFarm AI permite controlar animales, registrar raciones, producción y costos, y obtener recomendaciones nutricionales con IA. El proyecto está diseñado para presentación académica (8vo semestre): arquitectura moderna, segura y escalable, pero realista en alcance.

## Arquitectura

```
smartfarm_ai/
├── lib/                 # Cliente Flutter (Android)
│   ├── core/            # Config API, cliente HTTP
│   ├── database/        # SQLite local (modo offline)
│   ├── services/        # Servicios + repositorios
│   └── screens/         # UI
├── backend/             # API Node.js + Express + PostgreSQL
├── docker-compose.yml   # Orquestación local
├── k8s/                 # Manifiestos Kubernetes
└── docs/ARCHITECTURE.md # Documentación técnica detallada
```

Consulta [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) para diagramas, endpoints, variables de entorno y despliegue K8s.

Consulta [docs/AI_MODULE.md](docs/AI_MODULE.md) para el asistente ganadero inteligente (chat, síntomas, veterinarios).

## Sync remoto (Flutter ↔ API)

Cuando `USE_REMOTE_BACKEND=true`, los servicios públicos (`AnimalesService`, `RacionesService`, etc.) delegan automáticamente a la API REST mediante repositorios:

```
Servicio (facade) → Repository → LocalDataSource (SQLite) | ApiService (HTTP)
```

Entidades sincronizadas en modo remoto:
- Animales (CRUD completo)
- Raciones, producción, costos (listar, crear, eliminar)
- Dashboard (stats + series temporales)
- Analytics (calculado desde datos remotos)

Activación:
```bash
flutter run --dart-define=USE_REMOTE_BACKEND=true --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

## Inicio rápido

### 1. App móvil (modo local)
```bash
flutter pub get
flutter test
flutter run
```

### 2. Backend + base de datos (Docker)
```bash
docker compose up --build
```

Verificar:
```bash
curl http://localhost:3000/health
```

### 3. App móvil conectada al backend
```bash
flutter run --dart-define=USE_REMOTE_BACKEND=true --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

> Emulador Android: `10.0.2.2` = localhost del PC. En dispositivo físico use la IP LAN del servidor.

### 4. Backend sin Docker
```bash
cd backend
cp .env.example .env
npm install
npm run migrate && npm run seed
npm run dev
```

## Credenciales demo

- Email: `admin@smartfarm.ai`
- Password: `1234`

## Funcionalidades

- Login local o remoto (JWT)
- Dashboard con métricas agregadas
- CRUD de animales, raciones, producción, costos
- Recomendaciones IA (cliente local + proxy backend opcional)
- Tests de widgets (72+ tests)

## Stack tecnológico

| Capa | Tecnología |
|------|------------|
| Cliente | Flutter, Provider, SQLite |
| API | Node.js, Express |
| BD servidor | PostgreSQL 16 |
| Seguridad | JWT, bcrypt, Helmet, rate limiting |
| Contenedores | Docker, Docker Compose |
| Orquestación | Kubernetes (manifests incluidos) |

## API REST (resumen)

- `GET /health`
- `POST /api/auth/login`, `POST /api/auth/register`, `GET /api/auth/me`
- `CRUD /api/animales` + rutas anidadas (`raciones`, `produccion`, `costos`, `recomendaciones`)
- `GET /api/dashboard/summary`
- `POST /api/ia/recomendaciones`

Detalle completo en [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Variables de entorno

Backend: copiar `backend/.env.example` → `backend/.env`.

Cliente Flutter (dart-define):
- `USE_REMOTE_BACKEND=true|false`
- `API_BASE_URL=http://host:3000`

## Tests

```bash
flutter test
cd backend && npm install  # verificar arranque manual
```

## Notas para la presentación

1. **No se eliminó funcionalidad local**: SQLite sigue operativo sin backend.
2. **Separación de capas**: cliente, API, BD, IA proxy, middleware de seguridad.
3. **Escalabilidad**: API stateless + PostgreSQL + réplicas K8s.
4. **Seguridad**: OWASP básico (JWT, bcrypt, validación, rate limit, secretos en env).

## Licencia

Proyecto académico — SmartFarm AI.
