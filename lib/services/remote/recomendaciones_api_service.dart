import 'package:smartfarm_ai/core/network/api_client.dart';
import 'package:smartfarm_ai/models/recomendacion.dart';

class RecomendacionesApiService {
  RecomendacionesApiService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<Recomendacion>> getForAnimal(int animalId) async {
    final rows = await _client.getJsonList('/api/animales/$animalId/recomendaciones');
    return rows.map((r) => Recomendacion.fromMap(Map<String, Object?>.from(r as Map))).toList(growable: false);
  }

  Future<List<Recomendacion>> getLatest({int limit = 20}) async {
    final rows = await _client.getJsonList('/api/animales');
    final all = <Recomendacion>[];
    for (final animal in rows) {
      final id = (animal['id'] as num).toInt();
      final recs = await getForAnimal(id);
      all.addAll(recs);
    }
    all.sort((a, b) => b.fecha.compareTo(a.fecha));
    if (all.length <= limit) return all;
    return all.sublist(0, limit);
  }

  Future<Recomendacion> create({
    required int animalId,
    required String recomendacion,
    DateTime? fecha,
  }) async {
    final data = await _client.postJson('/api/animales/$animalId/recomendaciones', {
      'recomendacion': recomendacion.trim(),
      'fecha': (fecha ?? DateTime.now()).toIso8601String(),
    });
    return Recomendacion.fromMap(data);
  }

  Future<Recomendacion> update({
    required int animalId,
    required int id,
    required String recomendacion,
  }) async {
    final data = await _client.putJson('/api/animales/$animalId/recomendaciones/$id', {
      'recomendacion': recomendacion.trim(),
    });
    return Recomendacion.fromMap(data);
  }

  Future<void> delete(int animalId, int id) async {
    await _client.delete('/api/animales/$animalId/recomendaciones/$id');
  }

  /// Genera recomendación vía servicio IA del backend.
  Future<Recomendacion> generateForAnimal({required int animalId, String? context}) async {
    final data = await _client.postJson('/api/ia/recomendaciones', {
      'animalId': animalId,
      if (context != null) 'context': context,
    });
    return Recomendacion.fromMap(data);
  }
}
