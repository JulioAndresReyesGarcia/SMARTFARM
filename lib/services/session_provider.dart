import 'package:flutter/foundation.dart';

import 'package:smartfarm_ai/core/config/app_config.dart';
import 'package:smartfarm_ai/models/usuario.dart';
import 'package:smartfarm_ai/services/repositories/auth_repository.dart';

class SessionProvider extends ChangeNotifier {
  final AuthRepository _auth = AuthRepository();

  Usuario? _user;
  bool _busy = false;
  String? _error;

  Usuario? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get busy => _busy;
  String? get error => _error;

  /// Indica si la sesión usa backend remoto (JWT) o SQLite local.
  bool get isRemoteSession => AppConfig.useRemoteBackend;

  Future<bool> login({required String email, required String password}) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _auth.login(email: email, password: password);
      _user = user;
      if (user == null) _error = 'Credenciales inválidas';
      notifyListeners();
      return user != null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void logout() {
    _auth.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }
}
