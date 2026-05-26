import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/database/db_helpers.dart';
import 'package:smartfarm_ai/models/costo_alimentacion.dart';

class CostosLocalDataSource {
  Future<List<CostoAlimentacion>> getForAnimal(int animalId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'costos_alimentacion',
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'fecha DESC, id DESC',
    );
    return rows.map(CostoAlimentacion.fromMap).toList(growable: false);
  }

  Future<CostoAlimentacion?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('costos_alimentacion', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return CostoAlimentacion.fromMap(rows.first);
  }

  Future<CostoAlimentacion> create({
    required int animalId,
    required DateTime fecha,
    required double costo,
  }) async {
    final db = await AppDatabase.instance.database;
    final id = await db.insert(
      'costos_alimentacion',
      withDbTimestamps(CostoAlimentacion(id: 0, animalId: animalId, costo: costo, fecha: fecha).toInsertMap()),
    );
    final created = await getById(id);
    if (created == null) throw Exception('No se pudo recuperar el costo creado');
    return created;
  }

  Future<CostoAlimentacion> update(int id, {required double costo}) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'costos_alimentacion',
      {
        'costo': costo,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    final updated = await getById(id);
    if (updated == null) throw Exception('No se pudo recuperar el costo actualizado');
    return updated;
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('costos_alimentacion', where: 'id = ?', whereArgs: [id]);
  }
}
