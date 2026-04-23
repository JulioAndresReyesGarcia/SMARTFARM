import 'package:sqflite/sqflite.dart';

import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/models/animal.dart';
import 'package:smartfarm_ai/services/recomendaciones_service.dart';

class AnimalesService {
  final RecomendacionesService _recomendaciones = RecomendacionesService();

  Future<List<Animal>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('animales', orderBy: 'id DESC');
    return rows.map(Animal.fromMap).toList(growable: false);
  }

  Future<Animal?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('animales', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Animal.fromMap(rows.first);
  }

  Future<int> create({
    required String nombre,
    required double peso,
    required int edad,
    required String tipo,
  }) async {
    final db = await AppDatabase.instance.database;
    final id = await db.insert('animales', {
      'nombre': nombre.trim(),
      'peso': peso,
      'edad': edad,
      'tipo': tipo.trim(),
    });
    await _recomendaciones.generateForAnimal(animalId: id);
    return id;
  }

  Future<void> update(Animal animal) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'animales',
      animal.toInsertMap(),
      where: 'id = ?',
      whereArgs: [animal.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    await _recomendaciones.generateForAnimal(animalId: animal.id);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('animales', where: 'id = ?', whereArgs: [id]);
  }
}

