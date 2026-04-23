# SmartFarm AI

Aplicación Flutter local para gestión de ganado con SQLite (sqflite), CRUD completo y generación automática de recomendaciones nutricionales por peso.

## Demo login

- Email: `admin@smartfarm.ai`
- Password: `1234`

## Base de datos

Se crea automáticamente al primer inicio (`smartfarm_ai.db`) e incluye datos de ejemplo (mínimo 3 animales).

Tablas:

- `usuarios (id, nombre, email, password)`
- `animales (id, nombre, peso, edad, tipo)`
- `raciones (id, animal_id, fecha, cantidad, tipo_alimento)`
- `recomendaciones (id, animal_id, recomendacion, fecha)`
- `registros_produccion (id, animal_id, fecha, produccion)`
- `costos_alimentacion (id, animal_id, costo, fecha)`

## Recomendación nutricional

- Si `peso > 400` → dieta alta en proteína
- Si `peso < 300` → dieta de engorde
- En otro caso → dieta balanceada

## Ejecutar en Android Studio

1. Abre la carpeta `smartfarm_ai` en Android Studio.
2. Ejecuta `flutter pub get`.
3. Corre la app en un emulador/dispositivo Android.

## Nota (Windows)

Si `flutter pub get` muestra “Building with plugins requires symlink support”, activa **Developer Mode** en Windows:

- Abre Configuración → Privacidad y seguridad → Para desarrolladores → **Modo de desarrollador**
