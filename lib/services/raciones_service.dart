import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/models/racion.dart';

class RacionesService {
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

  Future<int> create({
    required int animalId,
    required DateTime fecha,
    required double cantidad,
    required String tipoAlimento,
  }) async {
    final db = await AppDatabase.instance.database;
    return db.insert(
      'raciones',
      Racion(
        id: 0,
        animalId: animalId,
        fecha: fecha,
        cantidad: cantidad,
        tipoAlimento: tipoAlimento.trim(),
      ).toInsertMap(),
    );
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('raciones', where: 'id = ?', whereArgs: [id]);
  }
}

