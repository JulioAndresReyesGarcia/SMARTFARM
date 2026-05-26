import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/database/db_helpers.dart';
import 'package:smartfarm_ai/models/registro_produccion.dart';

class ProduccionLocalDataSource {
  Future<List<RegistroProduccion>> getForAnimal(int animalId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'registros_produccion',
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'fecha DESC, id DESC',
    );
    return rows.map(RegistroProduccion.fromMap).toList(growable: false);
  }

  Future<RegistroProduccion?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('registros_produccion', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return RegistroProduccion.fromMap(rows.first);
  }

  Future<RegistroProduccion> create({
    required int animalId,
    required DateTime fecha,
    required double produccion,
  }) async {
    final db = await AppDatabase.instance.database;
    final id = await db.insert(
      'registros_produccion',
      withDbTimestamps(RegistroProduccion(id: 0, animalId: animalId, fecha: fecha, produccion: produccion).toInsertMap()),
    );
    final created = await getById(id);
    if (created == null) throw Exception('No se pudo recuperar el registro creado');
    return created;
  }

  Future<RegistroProduccion> update(int id, {required double produccion}) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'registros_produccion',
      {
        'produccion': produccion,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    final updated = await getById(id);
    if (updated == null) throw Exception('No se pudo recuperar el registro actualizado');
    return updated;
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('registros_produccion', where: 'id = ?', whereArgs: [id]);
  }
}
