import 'package:smartfarm_ai/models/dashboard_stats.dart';
import 'package:smartfarm_ai/models/time_series.dart';
import 'package:smartfarm_ai/services/repositories/dashboard_repository.dart';

class DashboardService {
  DashboardService({DashboardRepository? repository})
      : _repo = repository ?? DashboardRepository();

  final DashboardRepository _repo;

  Future<DashboardStats> getStats() async {
    try {
      return await _repo.getStats();
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  Future<List<TimeSeriesPoint>> getProductionOverTime({int days = 30}) async {
    try {
      return await _repo.getProductionOverTime(days: days);
    } catch (e) {
      throw Exception('Error al cargar producción: $e');
    }
  }

  Future<List<DualTimeSeriesPoint>> getCostsVsProduction({int days = 30}) async {
    try {
      return await _repo.getCostsVsProduction(days: days);
    } catch (e) {
      throw Exception('Error al cargar costos vs producción: $e');
    }
  }
}
