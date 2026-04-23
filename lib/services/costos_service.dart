import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/models/costo_alimentacion.dart';

class CostosService {
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

  Future<int> create({
    required int animalId,
    required DateTime fecha,
    required double costo,
  }) async {
    final db = await AppDatabase.instance.database;
    return db.insert(
      'costos_alimentacion',
      CostoAlimentacion(id: 0, animalId: animalId, costo: costo, fecha: fecha).toInsertMap(),
    );
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('costos_alimentacion', where: 'id = ?', whereArgs: [id]);
  }
}

