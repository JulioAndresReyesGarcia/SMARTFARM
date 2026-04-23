import 'package:sqflite/sqflite.dart';

import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/models/animal.dart';
import 'package:smartfarm_ai/models/recomendacion.dart';
import 'package:smartfarm_ai/services/nutrition_ai_service.dart';

class RecomendacionesService {
  final NutritionAIService _ai = NutritionAIService();

  Future<List<Recomendacion>> getForAnimal(int animalId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'recomendaciones',
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'fecha DESC, id DESC',
    );
    return rows.map(Recomendacion.fromMap).toList(growable: false);
  }

  Future<List<Recomendacion>> getLatest({int limit = 20}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('recomendaciones', orderBy: 'fecha DESC, id DESC', limit: limit);
    return rows.map(Recomendacion.fromMap).toList(growable: false);
  }

  Future<void> generateForAnimal({required int animalId}) async {
    final db = await AppDatabase.instance.database;
    final animalRows = await db.query('animales', where: 'id = ?', whereArgs: [animalId], limit: 1);
    if (animalRows.isEmpty) return;
    final animal = Animal.fromMap(animalRows.first);

    final text = _ai.recommendDetail(animal.peso);
    await db.insert(
      'recomendaciones',
      Recomendacion(id: 0, animalId: animalId, recomendacion: text, fecha: DateTime.now()).toInsertMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }
}

