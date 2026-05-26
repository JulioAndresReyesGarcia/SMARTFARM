import 'package:smartfarm_ai/models/animal.dart';
import 'package:smartfarm_ai/services/repositories/animales_repository.dart';

/// Fachada pública: delega a SQLite local o API remota según [AppConfig].
class AnimalesService {
  AnimalesService({AnimalesRepository? repository})
      : _repo = repository ?? AnimalesRepository();

  final AnimalesRepository _repo;

  Future<List<Animal>> getAll({String? tipo}) async {
    try {
      return await _repo.getAll(tipo: tipo);
    } catch (e) {
      throw Exception('Error al listar animales: $e');
    }
  }

  Future<Animal?> getById(int id) async {
    try {
      return await _repo.getById(id);
    } catch (e) {
      throw Exception('Error al obtener animal: $e');
    }
  }

  Future<Animal> create({
    required String nombre,
    required double peso,
    required int edad,
    required String tipo,
  }) async {
    try {
      return await _repo.create(nombre: nombre, peso: peso, edad: edad, tipo: tipo);
    } catch (e) {
      throw Exception('Error al crear animal: $e');
    }
  }

  Future<Animal> update(Animal animal) async {
    try {
      return await _repo.update(animal);
    } catch (e) {
      throw Exception('Error al actualizar animal: $e');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repo.delete(id);
    } catch (e) {
      throw Exception('Error al eliminar animal: $e');
    }
  }
}
