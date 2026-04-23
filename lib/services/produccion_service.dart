import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/models/registro_produccion.dart';

class ProduccionService {
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

  Future<int> create({
    required int animalId,
    required DateTime fecha,
    required double produccion,
  }) async {
    final db = await AppDatabase.instance.database;
    return db.insert(
      'registros_produccion',
      RegistroProduccion(id: 0, animalId: animalId, fecha: fecha, produccion: produccion).toInsertMap(),
    );
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('registros_produccion', where: 'id = ?', whereArgs: [id]);
  }
}

