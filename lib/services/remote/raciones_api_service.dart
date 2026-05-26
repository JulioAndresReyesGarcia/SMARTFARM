import 'package:smartfarm_ai/core/network/api_client.dart';
import 'package:smartfarm_ai/models/racion.dart';

class RacionesApiService {
  RacionesApiService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<Racion>> getForAnimal(int animalId) async {
    final rows = await _client.getJsonList('/api/animales/$animalId/raciones');
    return rows.map((r) => Racion.fromMap(Map<String, Object?>.from(r as Map))).toList(growable: false);
  }

  Future<Racion> create({
    required int animalId,
    required DateTime fecha,
    required double cantidad,
    required String tipoAlimento,
  }) async {
    final data = await _client.postJson('/api/animales/$animalId/raciones', {
      'fecha': fecha.toIso8601String(),
      'cantidad': cantidad,
      'tipo_alimento': tipoAlimento.trim(),
    });
    return Racion.fromMap(data);
  }

  Future<Racion> update({
    required int animalId,
    required int id,
    required double cantidad,
    required String tipoAlimento,
  }) async {
    final data = await _client.putJson('/api/animales/$animalId/raciones/$id', {
      'cantidad': cantidad,
      'tipo_alimento': tipoAlimento.trim(),
    });
    return Racion.fromMap(data);
  }

  Future<void> delete(int animalId, int id) async {
    await _client.delete('/api/animales/$animalId/raciones/$id');
  }
}
