import 'package:smartfarm_ai/core/config/app_config.dart';
import 'package:smartfarm_ai/data/local/costos_local.dart';
import 'package:smartfarm_ai/models/costo_alimentacion.dart';
import 'package:smartfarm_ai/services/remote/costos_api_service.dart';

class CostosRepository {
  CostosRepository({
    CostosLocalDataSource? local,
    CostosApiService? remote,
  })  : _local = local ?? CostosLocalDataSource(),
        _remote = remote ?? CostosApiService();

  final CostosLocalDataSource _local;
  final CostosApiService _remote;

  Future<List<CostoAlimentacion>> getAll({int? animalId}) async {
    if (animalId == null) throw Exception('animalId requerido');
    return getForAnimal(animalId);
  }

  Future<List<CostoAlimentacion>> getForAnimal(int animalId) {
    return AppConfig.useRemoteBackend
        ? _remote.getForAnimal(animalId)
        : _local.getForAnimal(animalId);
  }

  Future<CostoAlimentacion?> getById(int id) => _local.getById(id);

  Future<CostoAlimentacion> create({
    required int animalId,
    required DateTime fecha,
    required double costo,
  }) {
    if (AppConfig.useRemoteBackend) {
      return _remote.create(animalId: animalId, fecha: fecha, costo: costo);
    }
    return _local.create(animalId: animalId, fecha: fecha, costo: costo);
  }

  Future<CostoAlimentacion> update(
    int id, {
    required double costo,
    int? animalId,
  }) {
    if (AppConfig.useRemoteBackend) {
      if (animalId == null) throw Exception('animalId requerido en modo remoto');
      return _remote.update(animalId: animalId, id: id, costo: costo);
    }
    return _local.update(id, costo: costo);
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
