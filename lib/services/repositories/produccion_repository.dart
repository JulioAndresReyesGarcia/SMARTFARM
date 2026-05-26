import 'package:smartfarm_ai/core/config/app_config.dart';
import 'package:smartfarm_ai/data/local/produccion_local.dart';
import 'package:smartfarm_ai/models/registro_produccion.dart';
import 'package:smartfarm_ai/services/remote/produccion_api_service.dart';

class ProduccionRepository {
  ProduccionRepository({
    ProduccionLocalDataSource? local,
    ProduccionApiService? remote,
  })  : _local = local ?? ProduccionLocalDataSource(),
        _remote = remote ?? ProduccionApiService();

  final ProduccionLocalDataSource _local;
  final ProduccionApiService _remote;

  Future<List<RegistroProduccion>> getAll({int? animalId}) async {
    if (animalId == null) throw Exception('animalId requerido');
    return getForAnimal(animalId);
  }

  Future<List<RegistroProduccion>> getForAnimal(int animalId) {
    return AppConfig.useRemoteBackend
        ? _remote.getForAnimal(animalId)
        : _local.getForAnimal(animalId);
  }

  Future<RegistroProduccion?> getById(int id) => _local.getById(id);

  Future<RegistroProduccion> create({
    required int animalId,
    required DateTime fecha,
    required double produccion,
  }) {
    if (AppConfig.useRemoteBackend) {
      return _remote.create(animalId: animalId, fecha: fecha, produccion: produccion);
    }
    return _local.create(animalId: animalId, fecha: fecha, produccion: produccion);
  }

  Future<RegistroProduccion> update(
    int id, {
    required double produccion,
    int? animalId,
  }) {
    if (AppConfig.useRemoteBackend) {
      if (animalId == null) throw Exception('animalId requerido en modo remoto');
      return _remote.update(animalId: animalId, id: id, produccion: produccion);
    }
    return _local.update(id, produccion: produccion);
  }

  Future<void> delete(int id, {int? animalId}) async {
    if (AppConfig.useRemoteBackend) {
      if (animalId == null) throw Exception('animalId requerido en modo remoto');
      await _remote.delete(animalId, id);
      return;
    }
    await _local.delete(id);
  }
}
