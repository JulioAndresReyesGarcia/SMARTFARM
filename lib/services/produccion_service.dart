import 'package:smartfarm_ai/models/registro_produccion.dart';
import 'package:smartfarm_ai/services/repositories/produccion_repository.dart';

class ProduccionService {
  ProduccionService({ProduccionRepository? repository})
      : _repo = repository ?? ProduccionRepository();

  final ProduccionRepository _repo;

  Future<List<RegistroProduccion>> getAll({int? animalId}) async {
    try {
      return await _repo.getAll(animalId: animalId);
    } catch (e) {
      throw Exception('Error al listar producción: $e');
    }
  }

  Future<List<RegistroProduccion>> getForAnimal(int animalId) => getAll(animalId: animalId);

  Future<RegistroProduccion?> getById(int id) async {
    try {
      return await _repo.getById(id);
    } catch (e) {
      throw Exception('Error al obtener registro de producción: $e');
    }
  }

  Future<RegistroProduccion> create({
    required int animalId,
    required DateTime fecha,
    required double produccion,
  }) async {
    try {
      return await _repo.create(animalId: animalId, fecha: fecha, produccion: produccion);
    } catch (e) {
      throw Exception('Error al crear registro de producción: $e');
    }
  }

  Future<RegistroProduccion> update(
    int id, {
    required double produccion,
    int? animalId,
  }) async {
    try {
      return await _repo.update(id, produccion: produccion, animalId: animalId);
    } catch (e) {
      throw Exception('Error al actualizar registro de producción: $e');
    }
  }

  Future<void> delete(int id, {int? animalId}) async {
    try {
      await _repo.delete(id, animalId: animalId);
    } catch (e) {
      throw Exception('Error al eliminar registro de producción: $e');
    }
  }
}
