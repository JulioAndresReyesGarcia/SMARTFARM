import 'package:smartfarm_ai/core/network/api_client.dart';
import 'package:smartfarm_ai/models/costo_alimentacion.dart';

class CostosApiService {
  CostosApiService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<CostoAlimentacion>> getForAnimal(int animalId) async {
    final rows = await _client.getJsonList('/api/animales/$animalId/costos');
    return rows.map((r) => CostoAlimentacion.fromMap(Map<String, Object?>.from(r as Map))).toList(growable: false);
  }

  Future<CostoAlimentacion> create({
    required int animalId,
    required DateTime fecha,
    required double costo,
  }) async {
    final data = await _client.postJson('/api/animales/$animalId/costos', {
      'fecha': fecha.toIso8601String(),
      'costo': costo,
    });
    return CostoAlimentacion.fromMap(data);
  }

  Future<CostoAlimentacion> update({
    required int animalId,
    required int id,
    required double costo,
  }) async {
    final data = await _client.putJson('/api/animales/$animalId/costos/$id', {
      'costo': costo,
    });
    return CostoAlimentacion.fromMap(data);
  }

  Future<void> delete(int animalId, int id) async {
    await _client.delete('/api/animales/$animalId/costos/$id');
  }
}
