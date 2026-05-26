import 'package:smartfarm_ai/core/config/data_mode.dart';

/// Configuración central del cliente distribuido.
///
/// Activar modo remoto al ejecutar:
/// `flutter run --dart-define=USE_REMOTE_BACKEND=true --dart-define=API_BASE_URL=http://10.0.2.2:3000`
///
/// - Emulador Android: `10.0.2.2` apunta al localhost del host.
/// - Dispositivo físico: IP LAN de la máquina con el backend.
class AppConfig {
  AppConfig._();

  static const bool _useRemote = bool.fromEnvironment(
    'USE_REMOTE_BACKEND',
    defaultValue: false,
  );

  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static DataMode get dataMode => _useRemote ? DataMode.remote : DataMode.local;

  static bool get useRemoteBackend => dataMode == DataMode.remote;

  static String get apiBaseUrl => _apiBaseUrl.replaceAll(RegExp(r'/+$'), '');

  static Uri apiUri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$apiBaseUrl$normalized');
  }
}
