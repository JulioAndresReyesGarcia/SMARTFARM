import 'package:smartfarm_ai/core/config/app_config.dart';
import 'package:smartfarm_ai/data/local/animales_local.dart';
import 'package:smartfarm_ai/models/animal.dart';
import 'package:smartfarm_ai/services/remote/animales_api_service.dart';
import 'package:smartfarm_ai/services/repositories/recomendaciones_repository.dart';

/// Fachada local/remota para animales.
class AnimalesRepository {
  AnimalesRepository({
    AnimalesLocalDataSource? local,
    AnimalesApiService? remote,
  })  : _local = local ?? AnimalesLocalDataSource(),
        _remote = remote ?? AnimalesApiService();

  final AnimalesLocalDataSource _local;
  final AnimalesApiService _remote;
  RecomendacionesRepository? _recomendaciones;

  RecomendacionesRepository get _recs => _recomendaciones ??= RecomendacionesRepository();

  bool get _remoteMode => AppConfig.useRemoteBackend;

  Future<List<Animal>> getAll({String? tipo}) {
    return _remoteMode ? _remote.getAll(tipo: tipo) : _local.getAll(tipo: tipo);
  }

  Future<Animal?> getById(int id) {
    return _remoteMode ? _remote.getById(id) : _local.getById(id);
  }

  Future<Animal> create({
    required String nombre,
    required double peso,
    required int edad,
    required String tipo,
  }) async {
    final created = _remoteMode
        ? await _remote.create(nombre: nombre, peso: peso, edad: edad, tipo: tipo)
        : await _local.create(nombre: nombre, peso: peso, edad: edad, tipo: tipo);
    await _recs.generateForAnimal(animalId: created.id);
    return created;
  }

  Future<Animal> update(Animal animal) async {
    final updated = _remoteMode ? await _remote.update(animal) : await _local.update(animal);
    await _recs.generateForAnimal(animalId: updated.id);
    return updated;
  }

  Future<void> delete(int id) {
    return _remoteMode ? _remote.delete(id) : _local.delete(id);
  }
}
