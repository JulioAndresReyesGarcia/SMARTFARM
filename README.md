# SmartFarm AI BY CodeLink Solutions

Aplicación Flutter para gestión ganadera con **modo offline-first** en SQLite y un **backend opcional distribuido** en Node.js + PostgreSQL. La app incluye tablero, control de ganado, raciones, producción, costos y recomendaciones IA.

## Descripción

SmartFarm AI permite gestionar animales, registrar raciones, producción y costos, y obtener recomendaciones nutricionales inteligentes. Soporta:
- modo local con SQLite y login local
- modo remoto con backend Express + PostgreSQL
- IA híbrida: motor de recomendaciones local + OpenAI directo desde la app

El proyecto está pensado para presentación académica (8vo semestre) y muestra una arquitectura realista, modular y escalable.

## Arquitectura

```
smartfarm_ai/
├── lib/                 # Cliente Flutter
│   ├── ai/              # IA local + OpenAI/Gemini
│   ├── core/            # Configuración y cliente HTTP
│   ├── database/        # SQLite local
│   ├── models/          # Entidades de dominio
│   ├── screens/         # Pantallas de UI
│   ├── services/        # Providers, repositorios y lógica de negocio
│   └── widgets/         # Componentes reutilizables
├── backend/             # API Node.js + Express + PostgreSQL
├── docs/                # Documentación técnica
├── docker-compose.yml   # Orquestación local
└── k8s/                 # Manifiestos Kubernetes
```

Consulta [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) para diseño, endpoints, variables de entorno y despliegue.

Consulta [docs/AI_MODULE.md](docs/AI_MODULE.md) para detalles del asistente de IA y configuración de modelos.

## Modo remoto vs local

La app puede ejecutarse en:
- **Modo local**: datos guardados en SQLite y autenticación local.
- **Modo remoto**: datos y auth via API REST, con JWT y PostgreSQL.

El cambio se controla con `dart-define`:

```bash
flutter run --dart-define=USE_REMOTE_BACKEND=true --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

> En emulador Android `10.0.2.2` apunta a localhost del PC. En dispositivo físico, usa la IP LAN del servidor.

## IA inteligente

El módulo IA incluye:
- recomendación nutricional local basada en peso, edad, producción y costos
- chat conversacional de IA con contexto del animal
- soporte para OpenAI directo desde la app usando clave guardada en preferencias
- backend IA opcional cuando el modo remoto está activado

Para activar OpenAI:
- guardar `OPENAI_API_KEY` en `dart-define` o
- configurar la clave en el diálogo de ajustes de IA dentro de la app

## Inicio rápido

### 1. App Flutter
```bash
flutter pub get
flutter test
flutter run
```

### 2. Backend con Docker
```bash
docker compose up --build
```

Verificar servicio:
```bash
curl http://localhost:3000/health
```

### 3. App conectada al backend
```bash
flutter run --dart-define=USE_REMOTE_BACKEND=true --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

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

- Login local o remoto
- Dashboard con métricas y gráficos
- Gestión de animales (listar, crear, editar, borrar)
- Raciones, producción y costos por animal
- Recomendaciones IA y chat de IA
- Motor de recomendaciones local + OpenAI integrado
- Sincronización remota opcional con backend
- Tests de widgets en Flutter

## Stack tecnológico

| Capa | Tecnología |
|------|------------|
| Cliente | Flutter, Provider, SQLite, HTTP |
| API | Node.js, Express |
| BD servidor | PostgreSQL |
| Seguridad | JWT, Helmet, rate limiting, validación de entrada |
| Contenedores | Docker, Docker Compose |
| Orquestación | Kubernetes (manifests incluidos) |

## API REST (resumen)

- `GET /health`
- `POST /api/auth/login`
- `POST /api/auth/register`
- `GET /api/auth/me`
- `GET /api/animales`
- `POST /api/animales`
- `GET /api/animales/:id`
- `PUT /api/animales/:id`
- `DELETE /api/animales/:id`
- `GET /api/animales/:animalId/raciones`
- `POST /api/animales/:animalId/raciones`
- `PUT /api/animales/:animalId/raciones/:id`
- `DELETE /api/animales/:animalId/raciones/:id`
- `GET /api/animales/:animalId/produccion`
- `POST /api/animales/:animalId/produccion`
- `PUT /api/animales/:animalId/produccion/:id`
- `DELETE /api/animales/:animalId/produccion/:id`
- `GET /api/animales/:animalId/costos`
- `POST /api/animales/:animalId/costos`
- `PUT /api/animales/:animalId/costos/:id`
- `DELETE /api/animales/:animalId/costos/:id`
- `GET /api/animales/:animalId/recomendaciones`
- `POST /api/animales/:animalId/recomendaciones`
- `PUT /api/animales/:animalId/recomendaciones/:id`
- `DELETE /api/animales/:animalId/recomendaciones/:id`
- `GET /api/dashboard/stats`
- `GET /api/dashboard/summary`
- `GET /api/dashboard/production-over-time?days=30`
- `GET /api/dashboard/costs-vs-production?days=30`
- `POST /api/ia/chat`
- `POST /api/ia/recomendaciones`

## Variables de entorno

Backend: copiar `backend/.env.example` → `backend/.env`.

Cliente Flutter (dart-define):
- `USE_REMOTE_BACKEND=true|false`
- `API_BASE_URL=http://host:3000`
- `OPENAI_API_KEY=<tu_clave>` (opcional)
- `OPENAI_MODEL=gpt-4o-mini` (opcional)

## Tests

```bash
flutter test
cd backend && npm install
```

## Notas importantes

1. **Funcionalidad offline intacta**: SQLite y auth local permiten usar la app sin backend.
2. **La IA puede funcionar sin OpenAI** gracias al motor local integrado.
3. **El modo remoto habilita API REST completa** con JWT, recursos anidados y generación de IA.
4. **OpenAI se configura desde la app o por `dart-define`**.

## Licencia

Proyecto académico — SmartFarm AI.
