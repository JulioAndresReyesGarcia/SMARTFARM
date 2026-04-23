import 'package:flutter/foundation.dart';

import 'package:smartfarm_ai/models/usuario.dart';
import 'package:smartfarm_ai/services/usuarios_service.dart';

class SessionProvider extends ChangeNotifier {
  final UsuariosService _usuariosService = UsuariosService();

  Usuario? _user;
  bool _busy = false;

  Usuario? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get busy => _busy;

  Future<bool> login({required String email, required String password}) async {
    _busy = true;
    notifyListeners();
    try {
      final user = await _usuariosService.login(email: email, password: password);
      _user = user;
      notifyListeners();
      return user != null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}

