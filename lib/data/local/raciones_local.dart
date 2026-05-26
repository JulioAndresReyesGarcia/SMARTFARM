import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/database/db_helpers.dart';
import 'package:smartfarm_ai/models/racion.dart';

class RacionesLocalDataSource {
  Future<List<Racion>> getForAnimal(int animalId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'raciones',
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'fecha DESC, id DESC',
    );
    return rows.map(Racion.fromMap).toList(growable: false);
  }

  Future<Racion?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('raciones', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Racion.fromMap(rows.first);
  }

  Future<Racion> create({
    required int animalId,
    required DateTime fecha,
    required double cantidad,
    required String tipoAlimento,
  }) async {
    final db = await AppDatabase.instance.database;
    final id = await db.insert(
      'raciones',
      withDbTimestamps(Racion(
        id: 0,
        animalId: animalId,
        fecha: fecha,
        cantidad: cantidad,
        tipoAlimento: tipoAlimento.trim(),
      ).toInsertMap()),
    );
    final created = await getById(id);
    if (created == null) throw Exception('No se pudo recuperar la ración creada');
    return created;
  }

  Future<Racion> update(int id, {required double cantidad, required String tipoAlimento}) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'raciones',
      {
        'cantidad': cantidad,
        'tipo_alimento': tipoAlimento.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    final updated = await getById(id);
    if (updated == null) throw Exception('No se pudo recuperar la ración actualizada');
    return updated;
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('raciones', where: 'id = ?', whereArgs: [id]);
  }
}
