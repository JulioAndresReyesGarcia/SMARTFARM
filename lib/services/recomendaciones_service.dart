import 'package:sqflite/sqflite.dart';

import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/models/animal.dart';
import 'package:smartfarm_ai/models/recomendacion.dart';
import 'package:smartfarm_ai/services/ai_service.dart';

class RecomendacionesService {
  final AiService _ai;

  RecomendacionesService({AiService? ai}) : _ai = ai ?? AiService();

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

    final production = await _loadProductionHistory(db, animalId: animalId, limit: 30);
    final feeding = await _loadFeedingHistory(db, animalId: animalId, limit: 30);
    final costs = await _loadCostHistory(db, animalId: animalId, limit: 30);

    final rec = await _ai.recommend(
      AiAnimalContext(
        animalId: animalId,
        tipo: animal.tipo,
        pesoKg: animal.peso,
        edadMeses: animal.edad,
        productionHistory: production,
        feedingKgHistory: feeding.$1,
        feedingTypeHistory: feeding.$2,
        feedingCostsHistory: costs,
      ),
    );

    final text = rec.toStorageText();
    await db.insert(
      'recomendaciones',
      Recomendacion(id: 0, animalId: animalId, recomendacion: text, fecha: DateTime.now()).toInsertMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<double>> _loadProductionHistory(Database db, {required int animalId, required int limit}) async {
    final rows = await db.query(
      'registros_produccion',
      columns: ['produccion'],
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'fecha DESC, id DESC',
      limit: limit,
    );
    return rows.map((r) => (r['produccion'] as num).toDouble()).toList(growable: false);
  }

  Future<(List<double>, List<String>)> _loadFeedingHistory(Database db, {required int animalId, required int limit}) async {
    final rows = await db.query(
      'raciones',
      columns: ['cantidad', 'tipo_alimento'],
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'fecha DESC, id DESC',
      limit: limit,
    );
    final kg = <double>[];
    final types = <String>[];
    for (final r in rows) {
      kg.add((r['cantidad'] as num).toDouble());
      types.add((r['tipo_alimento'] as String?) ?? '');
    }
    return (kg, types);
  }

  Future<List<double>> _loadCostHistory(Database db, {required int animalId, required int limit}) async {
    final rows = await db.query(
      'costos_alimentacion',
      columns: ['costo'],
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'fecha DESC, id DESC',
      limit: limit,
    );
    return rows.map((r) => (r['costo'] as num).toDouble()).toList(growable: false);
  }
}

