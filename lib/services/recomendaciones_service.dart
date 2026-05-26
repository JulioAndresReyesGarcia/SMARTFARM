import 'package:smartfarm_ai/models/recomendacion.dart';
import 'package:smartfarm_ai/services/repositories/recomendaciones_repository.dart';

class RecomendacionesService {
  RecomendacionesService({RecomendacionesRepository? repository})
      : _repo = repository ?? RecomendacionesRepository();

  final RecomendacionesRepository _repo;

  Future<List<Recomendacion>> getAll({int? animalId}) async {
    try {
      return await _repo.getAll(animalId: animalId);
    } catch (e) {
      throw Exception('Error al listar recomendaciones: $e');
    }
  }

  Future<List<Recomendacion>> getForAnimal(int animalId) => getAll(animalId: animalId);

  Future<Recomendacion?> getById(int id) async {
    try {
      return await _repo.getById(id);
    } catch (e) {
      throw Exception('Error al obtener recomendación: $e');
    }
  }

  Future<List<Recomendacion>> getLatest({int limit = 20}) async {
    try {
      return await _repo.getLatest(limit: limit);
    } catch (e) {
      throw Exception('Error al obtener recomendaciones recientes: $e');
    }
  }

  Future<String?> getLatestBadgeForAnimal(int animalId) => _repo.getLatestBadgeForAnimal(animalId);

  Future<Map<int, String>> getLatestBadgesForAnimals(List<int> animalIds) =>
      _repo.getLatestBadgesForAnimals(animalIds);

  Future<Recomendacion> create({
    required int animalId,
    required String recomendacion,
    DateTime? fecha,
  }) async {
    try {
      return await _repo.create(animalId: animalId, recomendacion: recomendacion, fecha: fecha);
    } catch (e) {
      throw Exception('Error al crear recomendación: $e');
    }
  }

  Future<Recomendacion> update(
    int id, {
    required String recomendacion,
    int? animalId,
  }) async {
    try {
      return await _repo.update(id, recomendacion: recomendacion, animalId: animalId);
    } catch (e) {
      throw Exception('Error al actualizar recomendación: $e');
    }
  }

  Future<void> delete(int id, {int? animalId}) async {
    try {
      await _repo.delete(id, animalId: animalId);
    } catch (e) {
      throw Exception('Error al eliminar recomendación: $e');
    }
  }

  Future<Recomendacion> generateForAnimal({required int animalId}) async {
    try {
      return await _repo.generateForAnimal(animalId: animalId);
    } catch (e) {
      throw Exception('Error al generar recomendación: $e');
    }
  }
}
