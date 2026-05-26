import 'package:smartfarm_ai/models/costo_alimentacion.dart';
import 'package:smartfarm_ai/services/repositories/costos_repository.dart';

class CostosService {
  CostosService({CostosRepository? repository})
      : _repo = repository ?? CostosRepository();

  final CostosRepository _repo;

  Future<List<CostoAlimentacion>> getAll({int? animalId}) async {
    try {
      return await _repo.getAll(animalId: animalId);
    } catch (e) {
      throw Exception('Error al listar costos: $e');
    }
  }

  Future<List<CostoAlimentacion>> getForAnimal(int animalId) => getAll(animalId: animalId);

  Future<CostoAlimentacion?> getById(int id) async {
    try {
      return await _repo.getById(id);
    } catch (e) {
      throw Exception('Error al obtener costo: $e');
    }
  }

  Future<CostoAlimentacion> create({
    required int animalId,
    required DateTime fecha,
    required double costo,
  }) async {
    try {
      return await _repo.create(animalId: animalId, fecha: fecha, costo: costo);
    } catch (e) {
      throw Exception('Error al crear costo: $e');
    }
  }

  Future<CostoAlimentacion> update(
    int id, {
    required double costo,
    int? animalId,
  }) async {
    try {
      return await _repo.update(id, costo: costo, animalId: animalId);
    } catch (e) {
      throw Exception('Error al actualizar costo: $e');
    }
  }

  Future<void> delete(int id, {int? animalId}) async {
    try {
      await _repo.delete(id, animalId: animalId);
    } catch (e) {
      throw Exception('Error al eliminar costo: $e');
    }
  }
}
