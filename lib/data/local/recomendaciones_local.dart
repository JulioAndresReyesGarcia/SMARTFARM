import 'package:sqflite/sqflite.dart';

import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/database/db_helpers.dart';
import 'package:smartfarm_ai/models/animal.dart';
import 'package:smartfarm_ai/models/recomendacion.dart';
import 'package:smartfarm_ai/services/ai_service.dart';
import 'package:smartfarm_ai/data/local/analytics_local.dart';

class RecomendacionesLocalDataSource {
  RecomendacionesLocalDataSource({
    AiService? ai,
    AnalyticsLocalDataSource? analytics,
  })  : _ai = ai ?? AiService(),
        _analytics = analytics ?? AnalyticsLocalDataSource();

  final AiService _ai;
  final AnalyticsLocalDataSource _analytics;

  Future<List<Recomendacion>> getAll({int? animalId}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'recomendaciones',
      where: animalId == null ? null : 'animal_id = ?',
      whereArgs: animalId == null ? null : [animalId],
      orderBy: 'fecha DESC, id DESC',
    );
    return rows.map(Recomendacion.fromMap).toList(growable: false);
  }

  Future<List<Recomendacion>> getForAnimal(int animalId) => getAll(animalId: animalId);

  Future<Recomendacion?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('recomendaciones', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Recomendacion.fromMap(rows.first);
  }

  Future<List<Recomendacion>> getLatest({int limit = 20}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('recomendaciones', orderBy: 'fecha DESC, id DESC', limit: limit);
    return rows.map(Recomendacion.fromMap).toList(growable: false);
  }

  Future<Recomendacion> create({
    required int animalId,
    required String recomendacion,
    DateTime? fecha,
  }) async {
    final db = await AppDatabase.instance.database;
    final rec = Recomendacion(
      id: 0,
      animalId: animalId,
      recomendacion: recomendacion.trim(),
      fecha: fecha ?? DateTime.now(),
    );
    final id = await db.insert('recomendaciones', withDbTimestamps(rec.toInsertMap()), conflictAlgorithm: ConflictAlgorithm.abort);
    final created = await getById(id);
    if (created == null) throw Exception('No se pudo recuperar la recomendación creada');
    return created;
  }

  Future<Recomendacion> update(int id, {required String recomendacion}) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'recomendaciones',
      {
        'recomendacion': recomendacion.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    final updated = await getById(id);
    if (updated == null) throw Exception('No se pudo recuperar la recomendación actualizada');
    return updated;
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('recomendaciones', where: 'id = ?', whereArgs: [id]);
  }

  Future<Recomendacion> generateForAnimal({
    required Animal animal,
    required int animalId,
  }) async {
    final production = await _analytics.loadDoubles(
      table: 'registros_produccion',
      animalId: animalId,
      field: 'produccion',
    );
    final feedingKg = await _analytics.loadDoubles(
      table: 'raciones',
      animalId: animalId,
      field: 'cantidad',
    );
    final feedingTypes = await _analytics.loadStrings(
      table: 'raciones',
      animalId: animalId,
      field: 'tipo_alimento',
    );
    final costs = await _analytics.loadDoubles(
      table: 'costos_alimentacion',
      animalId: animalId,
      field: 'costo',
    );

    final rec = await _ai.recommend(
      AiAnimalContext(
        animalId: animalId,
        tipo: animal.tipo,
        pesoKg: animal.peso,
        edadMeses: animal.edad,
        productionHistory: production,
        feedingKgHistory: feedingKg,
        feedingTypeHistory: feedingTypes,
        feedingCostsHistory: costs,
      ),
    );

    return create(animalId: animalId, recomendacion: rec.toStorageText());
  }
}
