import 'package:smartfarm_ai/core/network/api_client.dart';
import 'package:smartfarm_ai/models/registro_produccion.dart';

class ProduccionApiService {
  ProduccionApiService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<RegistroProduccion>> getForAnimal(int animalId) async {
    final rows = await _client.getJsonList('/api/animales/$animalId/produccion');
    return rows.map((r) => RegistroProduccion.fromMap(Map<String, Object?>.from(r as Map))).toList(growable: false);
  }

  Future<RegistroProduccion> create({
    required int animalId,
    required DateTime fecha,
    required double produccion,
  }) async {
    final data = await _client.postJson('/api/animales/$animalId/produccion', {
      'fecha': fecha.toIso8601String(),
      'produccion': produccion,
    });
    return RegistroProduccion.fromMap(data);
  }

  Future<RegistroProduccion> update({
    required int animalId,
    required int id,
    required double produccion,
  }) async {
    final data = await _client.putJson('/api/animales/$animalId/produccion/$id', {
      'produccion': produccion,
    });
    return RegistroProduccion.fromMap(data);
  }

  Future<void> delete(int animalId, int id) async {
    await _client.delete('/api/animales/$animalId/produccion/$id');
  }
}
