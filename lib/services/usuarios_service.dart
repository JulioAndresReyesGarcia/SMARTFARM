import 'package:sqflite/sqflite.dart';

import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/models/usuario.dart';

class UsuariosService {
  Future<Usuario?> login({required String email, required String password}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'usuarios',
      where: 'email = ? AND password = ?',
      whereArgs: [email.trim(), password],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Usuario.fromMap(rows.first);
  }

  Future<int> create({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final db = await AppDatabase.instance.database;
    return db.insert(
      'usuarios',
      {'nombre': nombre.trim(), 'email': email.trim(), 'password': password},
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }
}

