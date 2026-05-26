import 'package:smartfarm_ai/core/config/app_config.dart';
import 'package:smartfarm_ai/core/network/api_client.dart';
import 'package:smartfarm_ai/models/usuario.dart';
import 'package:smartfarm_ai/services/remote/auth_api_service.dart';
import 'package:smartfarm_ai/services/usuarios_service.dart';

/// Fachada de autenticación: SQLite local o API remota según [AppConfig].
class AuthRepository {
  AuthRepository({
    UsuariosService? local,
    ApiClient? apiClient,
    AuthApiService? remote,
  })  : _local = local ?? UsuariosService(),
        _remote = remote ?? AuthApiService(apiClient ?? ApiClient.instance);

  final UsuariosService _local;
  final AuthApiService _remote;

  bool get isRemote => AppConfig.useRemoteBackend;

  Future<Usuario?> login({required String email, required String password}) async {
    if (isRemote) {
      final result = await _remote.login(email: email, password: password);
      ApiClient.instance.setToken(result.token);
      return result.user;
    }
    return _local.login(email: email, password: password);
  }

  void logout() {
    if (isRemote) {
      ApiClient.instance.setToken(null);
    }
  }
}
