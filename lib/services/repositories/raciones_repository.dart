import 'package:smartfarm_ai/core/config/app_config.dart';
import 'package:smartfarm_ai/data/local/raciones_local.dart';
import 'package:smartfarm_ai/models/racion.dart';
import 'package:smartfarm_ai/services/remote/raciones_api_service.dart';

class RacionesRepository {
  RacionesRepository({
    RacionesLocalDataSource? local,
    RacionesApiService? remote,
  })  : _local = local ?? RacionesLocalDataSource(),
        _remote = remote ?? RacionesApiService();

  final RacionesLocalDataSource _local;
  final RacionesApiService _remote;

  Future<List<Racion>> getAll({int? animalId}) async {
    if (animalId == null) {
      throw Exception('animalId requerido');
    }
    return getForAnimal(animalId);
  }

  Future<List<Racion>> getForAnimal(int animalId) {
    return AppConfig.useRemoteBackend
        ? _remote.getForAnimal(animalId)
        : _local.getForAnimal(animalId);
  }

  Future<Racion?> getById(int id) => _local.getById(id);

  Future<Racion> create({
    required int animalId,
    required DateTime fecha,
    required double cantidad,
    required String tipoAlimento,
  }) {
    if (AppConfig.useRemoteBackend) {
      return _remote.create(
        animalId: animalId,
        fecha: fecha,
        cantidad: cantidad,
        tipoAlimento: tipoAlimento,
      );
    }
    return _local.create(
      animalId: animalId,
      fecha: fecha,
      cantidad: cantidad,
      tipoAlimento: tipoAlimento,
    );
  }

  Future<Racion> update(
    int id, {
    required double cantidad,
    required String tipoAlimento,
    int? animalId,
  }) {
    if (AppConfig.useRemoteBackend) {
      if (animalId == null) throw Exception('animalId requerido en modo remoto');
      return _remote.update(
        animalId: animalId,
        id: id,
        cantidad: cantidad,
        tipoAlimento: tipoAlimento,
      );
    }
    return _local.update(id, cantidad: cantidad, tipoAlimento: tipoAlimento);
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
