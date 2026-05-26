import 'package:smartfarm_ai/core/network/api_client.dart';
import 'package:smartfarm_ai/models/animal.dart';

/// Cliente remoto CRUD de animales.
class AnimalesApiService {
  AnimalesApiService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<Animal>> getAll({String? tipo}) async {
    final path = tipo == null || tipo.trim().isEmpty
        ? '/api/animales'
        : '/api/animales?tipo=${Uri.encodeQueryComponent(tipo.trim())}';
    final rows = await _client.getJsonList(path);
    return rows.map((r) => Animal.fromMap(Map<String, Object?>.from(r as Map))).toList(growable: false);
  }

  Future<Animal?> getById(int id) async {
    try {
      final data = await _client.getJson('/api/animales/$id');
      return Animal.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  Future<Animal> create({
    required String nombre,
    required double peso,
    required int edad,
    required String tipo,
  }) async {
    final data = await _client.postJson('/api/animales', {
      'nombre': nombre.trim(),
      'peso': peso,
      'edad': edad,
      'tipo': tipo.trim(),
    });
    return Animal.fromMap(data);
  }

  Future<Animal> update(Animal animal) async {
    final data = await _client.putJson('/api/animales/${animal.id}', {
      'nombre': animal.nombre,
      'peso': animal.peso,
      'edad': animal.edad,
      'tipo': animal.tipo,
    });
    return Animal.fromMap(data);
  }

  Future<void> delete(int id) async {
    await _client.delete('/api/animales/$id');
  }
}
