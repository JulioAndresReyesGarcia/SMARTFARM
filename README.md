# SmartFarm AI.

Aplicación Flutter para la gestión de ganado y la generación de recomendaciones de alimentación basadas en datos.

## Descripción

`SmartFarm AI` es un proyecto de gestión agrícola que permite controlar animales, registrar raciones, producción y costos, y obtener recomendaciones nutricionales generadas por la funcionalidad de IA integrada.

La app está diseñada como un prototipo local con persistencia en SQLite y una interfaz moderna con navegación inferior.

## Funcionalidades principales

- Inicio de sesión local para acceder a la aplicación
- Dashboard con métricas clave:
  - Número de animales
  - Número de raciones registradas
  - Producción total
  - Costos totales
- Gestión de ganado:
  - Registro de animales
  - Edición de animales
  - Eliminación de animales
- Detalle de animal con pestañas:
  - Resumen del animal
  - Historial de raciones
  - Historial de producción
  - Historial de costos
- Generación de recomendaciones de IA para la nutrición del ganado
- Importante: los datos se almacenan localmente usando SQLite

## Estructura del proyecto

- `lib/main.dart`: punto de entrada de la aplicación
- `lib/screens/`: pantallas principales de la app
  - `login_screen.dart`
  - `home_shell.dart`
  - `dashboard_screen.dart`
  - `animals_screen.dart`
  - `animal_form_screen.dart`
  - `animal_detail_screen.dart`
  - `recommendations_screen.dart`
- `lib/services/`: proveedores y servicios de datos
  - `session_provider.dart`
  - `animals_provider.dart`
  - `dashboard_provider.dart`
  - Servicios SQLite para animales, raciones, producción, costos, recomendaciones y usuarios
- `lib/models/`: modelos de dominio
  - `animal.dart`
  - `usuario.dart`
  - `costo_alimentacion.dart`
  - `racion.dart`
  - `recomendacion.dart`
  - `registro_produccion.dart`
- `lib/widgets/`: componentes reutilizables de UI
- `lib/theme/`: definición de tema y estilos
- `lib/utils/`: utilidades de formato y otras helpers

## Dependencias

El proyecto utiliza las siguientes dependencias principales:

- `flutter`
- `provider`
- `sqflite`
- `path`
- `path_provider`
- `intl`

## Instalación y ejecución

1. Asegúrate de tener Flutter instalado y configurado.
2. Desde la raíz del proyecto:

```bash
flutter pub get
flutter run
```

> Si deseas ejecutar en un dispositivo físico o emulador, selecciona el target apropiado antes de ejecutar `flutter run`.

## Credenciales de demo

- Email: `admin@smartfarm.ai`
- Password: `1234`

## Cómo usar

1. Inicia sesión con las credenciales de demo.
2. En la pestaña `Inicio`, revisa el estado general del sistema.
3. En la pestaña `Ganado`, registra un nuevo animal o abre uno existente.
4. Desde el detalle del animal, agrega raciones, producción o costos.
5. En la pestaña `IA`, genera o refresca recomendaciones nutricionales.

## Notas de desarrollo

- La aplicación usa `MultiProvider` para manejar estado global.
- `SessionProvider` controla la sesión de usuario.
- `AnimalsProvider` sincroniza la lista de animales y las actualizaciones.
- `DashboardProvider` obtiene métricas agregadas para el dashboard.

## Siguiente pasos sugeridos

- Integrar autenticación real o un backend remoto.
- Añadir sincronización en la nube.
- Mejorar la generación de recomendaciones con un modelo de IA real.
- Añadir pruebas unitarias y de widget.

