import 'package:smartfarm_ai/models/time_series.dart';
import 'package:smartfarm_ai/services/repositories/analytics_repository.dart';

class AnalyticsService {
  AnalyticsService({AnalyticsRepository? repository})
      : _repo = repository ?? AnalyticsRepository();

  final AnalyticsRepository _repo;

  Future<List<TimeSeriesPoint>> getAnimalProductionSeries(int animalId, {int days = 30}) async {
    try {
      return await _repo.getAnimalProductionSeries(animalId, days: days);
    } catch (e) {
      throw Exception('Error al cargar producción del animal: $e');
    }
  }

  Future<DualTimeSeriesPoint?> getAnimalFeedingVsProductionPoint(int animalId, {int days = 14}) async {
    try {
      return await _repo.getAnimalFeedingVsProductionPoint(animalId, days: days);
    } catch (e) {
      throw Exception('Error al cargar alimentación vs producción: $e');
    }
  }

  Future<List<double>> loadDoubles({
    required String table,
    required int animalId,
    required String field,
    int limit = 30,
  }) async {
    try {
      return await _repo.loadDoubles(table: table, animalId: animalId, field: field, limit: limit);
    } catch (e) {
      throw Exception('Error al cargar historial de $field: $e');
    }
  }

  Future<List<String>> loadStrings({
    required String table,
    required int animalId,
    required String field,
    int limit = 30,
  }) async {
    try {
      return await _repo.loadStrings(table: table, animalId: animalId, field: field, limit: limit);
    } catch (e) {
      throw Exception('Error al cargar historial de $field: $e');
    }
  }
}
