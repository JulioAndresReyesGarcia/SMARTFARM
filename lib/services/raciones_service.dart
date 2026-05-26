import 'package:smartfarm_ai/models/racion.dart';
import 'package:smartfarm_ai/services/repositories/raciones_repository.dart';

class RacionesService {
  RacionesService({RacionesRepository? repository})
      : _repo = repository ?? RacionesRepository();

  final RacionesRepository _repo;

  Future<List<Racion>> getAll({int? animalId}) async {
    try {
      return await _repo.getAll(animalId: animalId);
    } catch (e) {
      throw Exception('Error al listar raciones: $e');
    }
  }

  Future<List<Racion>> getForAnimal(int animalId) => getAll(animalId: animalId);

  Future<Racion?> getById(int id) async {
    try {
      return await _repo.getById(id);
    } catch (e) {
      throw Exception('Error al obtener ración: $e');
    }
  }

  Future<Racion> create({
    required int animalId,
    required DateTime fecha,
    required double cantidad,
    required String tipoAlimento,
  }) async {
    try {
      return await _repo.create(
        animalId: animalId,
        fecha: fecha,
        cantidad: cantidad,
        tipoAlimento: tipoAlimento,
      );
    } catch (e) {
      throw Exception('Error al crear ración: $e');
    }
  }

  Future<Racion> update(
    int id, {
    required double cantidad,
    required String tipoAlimento,
    int? animalId,
  }) async {
    try {
      return await _repo.update(
        id,
        cantidad: cantidad,
        tipoAlimento: tipoAlimento,
        animalId: animalId,
      );
    } catch (e) {
      throw Exception('Error al actualizar ración: $e');
    }
  }

  Future<void> delete(int id, {int? animalId}) async {
    try {
      await _repo.delete(id, animalId: animalId);
    } catch (e) {
      throw Exception('Error al eliminar ración: $e');
    }
  }
}
