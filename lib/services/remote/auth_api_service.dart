import 'package:smartfarm_ai/core/network/api_client.dart';
import 'package:smartfarm_ai/core/network/api_exception.dart';
import 'package:smartfarm_ai/models/usuario.dart';

/// Autenticación contra el backend distribuido (JWT).
class AuthApiService {
  AuthApiService(this._client);

  final ApiClient _client;

  Future<({Usuario user, String token})> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.postJson('/api/auth/login', {
      'email': email.trim(),
      'password': password,
    });

    final token = data['token'] as String?;
    final userMap = data['user'] as Map<String, dynamic>?;
    if (token == null || userMap == null) {
      throw const ApiException('Respuesta de login inválida');
    }

    _client.setToken(token);
    return (
      token: token,
      user: Usuario(
        id: (userMap['id'] as num).toInt(),
        nombre: userMap['nombre'] as String,
        email: userMap['email'] as String,
      ),
    );
  }

  Future<bool> healthCheck() async {
    try {
      await _client.getJson('/health');
      return true;
    } catch (_) {
      return false;
    }
  }
}
