import 'package:smartfarm_ai/core/config/app_config.dart';
import 'package:smartfarm_ai/data/local/animales_local.dart';
import 'package:smartfarm_ai/data/local/recomendaciones_local.dart';
import 'package:smartfarm_ai/models/recomendacion.dart';
import 'package:smartfarm_ai/services/remote/animales_api_service.dart';
import 'package:smartfarm_ai/services/remote/recomendaciones_api_service.dart';

class RecomendacionesRepository {
  RecomendacionesRepository({
    RecomendacionesLocalDataSource? local,
    RecomendacionesApiService? remote,
    AnimalesLocalDataSource? animalesLocal,
    AnimalesApiService? animalesRemote,
  })  : _local = local ?? RecomendacionesLocalDataSource(),
        _remote = remote ?? RecomendacionesApiService(),
        _animalesLocal = animalesLocal ?? AnimalesLocalDataSource(),
        _animalesRemote = animalesRemote ?? AnimalesApiService();

  final RecomendacionesLocalDataSource _local;
  final RecomendacionesApiService _remote;
  final AnimalesLocalDataSource _animalesLocal;
  final AnimalesApiService _animalesRemote;

  Future<List<Recomendacion>> getAll({int? animalId}) {
    if (AppConfig.useRemoteBackend && animalId != null) {
      return _remote.getForAnimal(animalId);
    }
    return _local.getAll(animalId: animalId);
  }

  Future<List<Recomendacion>> getForAnimal(int animalId) => getAll(animalId: animalId);

  Future<Recomendacion?> getById(int id) => _local.getById(id);

  Future<List<Recomendacion>> getLatest({int limit = 20}) {
    return AppConfig.useRemoteBackend
        ? _remote.getLatest(limit: limit)
        : _local.getLatest(limit: limit);
  }

  Future<String?> getLatestBadgeForAnimal(int animalId) async {
    try {
      final recs = await getForAnimal(animalId);
      if (recs.isEmpty) return null;
      final text = recs.first.recomendacion.trim();
      if (text.isEmpty) return null;
      final firstLine = text.split('\n').first.trim();
      if (firstLine.length <= 48) return firstLine;
      return '${firstLine.substring(0, 45)}…';
    } catch (_) {
      return null;
    }
  }

  Future<Map<int, String>> getLatestBadgesForAnimals(List<int> animalIds) async {
    final badges = <int, String>{};
    for (final id in animalIds) {
      final badge = await getLatestBadgeForAnimal(id);
      if (badge != null) badges[id] = badge;
    }
    return badges;
  }

  Future<Recomendacion> create({
    required int animalId,
    required String recomendacion,
    DateTime? fecha,
  }) {
    if (AppConfig.useRemoteBackend) {
      return _remote.create(animalId: animalId, recomendacion: recomendacion, fecha: fecha);
    }
    return _local.create(animalId: animalId, recomendacion: recomendacion, fecha: fecha);
  }

  Future<Recomendacion> update(
    int id, {
    required String recomendacion,
    int? animalId,
  }) {
    if (AppConfig.useRemoteBackend) {
      if (animalId == null) throw Exception('animalId requerido en modo remoto');
      return _remote.update(animalId: animalId, id: id, recomendacion: recomendacion);
    }
    return _local.update(id, recomendacion: recomendacion);
  }

  Future<void> delete(int id, {int? animalId}) async {
    if (AppConfig.useRemoteBackend) {
      if (animalId == null) throw Exception('animalId requerido en modo remoto');
      await _remote.delete(animalId, id);
      return;
    }
    await _local.delete(id);
  }

  Future<Recomendacion> generateForAnimal({required int animalId}) async {
    if (AppConfig.useRemoteBackend) {
      return _remote.generateForAnimal(animalId: animalId);
    }
    final animal = await _animalesLocal.getById(animalId);
    if (animal == null) throw Exception('Animal no encontrado');
    return _local.generateForAnimal(animal: animal, animalId: animalId);
  }
}
