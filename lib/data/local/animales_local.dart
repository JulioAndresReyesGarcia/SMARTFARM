import 'package:sqflite/sqflite.dart';

import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/database/db_helpers.dart';
import 'package:smartfarm_ai/models/animal.dart';

/// Persistencia SQLite de animales (capa local del sync).
class AnimalesLocalDataSource {
  Future<List<Animal>> getAll({String? tipo}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'animales',
      where: tipo == null ? null : 'tipo = ?',
      whereArgs: tipo == null ? null : [tipo.trim()],
      orderBy: 'id DESC',
    );
    return rows.map(Animal.fromMap).toList(growable: false);
  }

  Future<Animal?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('animales', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Animal.fromMap(rows.first);
  }

  Future<Animal> create({
    required String nombre,
    required double peso,
    required int edad,
    required String tipo,
  }) async {
    final db = await AppDatabase.instance.database;
    final id = await db.insert('animales', withDbTimestamps({
      'nombre': nombre.trim(),
      'peso': peso,
      'edad': edad,
      'tipo': tipo.trim(),
    }));
    final created = await getById(id);
    if (created == null) throw Exception('No se pudo recuperar el animal creado');
    return created;
  }

  Future<Animal> update(Animal animal) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'animales',
      {
        ...animal.toInsertMap(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [animal.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    final updated = await getById(animal.id);
    if (updated == null) throw Exception('No se pudo recuperar el animal actualizado');
    return updated;
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('animales', where: 'id = ?', whereArgs: [id]);
  }
}
