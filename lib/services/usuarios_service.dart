import 'package:sqflite/sqflite.dart';

import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/database/db_helpers.dart';
import 'package:smartfarm_ai/models/usuario.dart';

class UsuariosService {
  Future<List<Usuario>> getAll() async {
    try {
      final db = await AppDatabase.instance.database;
      final rows = await db.query('usuarios', orderBy: 'id ASC');
      return rows.map(Usuario.fromMap).toList(growable: false);
    } catch (e) {
      throw Exception('Error al listar usuarios: $e');
    }
  }

  Future<Usuario?> getById(int id) async {
    try {
      final db = await AppDatabase.instance.database;
      final rows = await db.query('usuarios', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return Usuario.fromMap(rows.first);
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  Future<Usuario?> login({required String email, required String password}) async {
    try {
      final db = await AppDatabase.instance.database;
      final rows = await db.query(
        'usuarios',
        where: 'email = ? AND password = ?',
        whereArgs: [email.trim(), password],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return Usuario.fromMap(rows.first);
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  Future<Usuario> create({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      final db = await AppDatabase.instance.database;
      final id = await db.insert(
        'usuarios',
        withDbTimestamps({'nombre': nombre.trim(), 'email': email.trim(), 'password': password}),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      final created = await getById(id);
      if (created == null) throw Exception('No se pudo recuperar el usuario creado');
      return created;
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  Future<Usuario> update(int id, {required String nombre, required String email}) async {
    try {
      final db = await AppDatabase.instance.database;
      await db.update(
        'usuarios',
        {
          'nombre': nombre.trim(),
          'email': email.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      final updated = await getById(id);
      if (updated == null) throw Exception('No se pudo recuperar el usuario actualizado');
      return updated;
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  Future<void> delete(int id) async {
    try {
      final db = await AppDatabase.instance.database;
      await db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }
}
