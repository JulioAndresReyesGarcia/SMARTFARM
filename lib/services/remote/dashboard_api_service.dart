import 'package:smartfarm_ai/core/network/api_client.dart';
import 'package:smartfarm_ai/models/dashboard_stats.dart';
import 'package:smartfarm_ai/models/time_series.dart';

class DashboardApiService {
  DashboardApiService([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<DashboardStats> getStats() async {
    final data = await _client.getJson('/api/dashboard/stats');
    return DashboardStats(
      animales: (data['animales'] as num).toInt(),
      raciones: (data['raciones'] as num).toInt(),
      produccion: (data['produccion'] as num).toInt(),
      costos: (data['costos'] as num).toInt(),
    );
  }

  Future<List<TimeSeriesPoint>> getProductionOverTime({int days = 30}) async {
    final rows = await _client.getJsonList('/api/dashboard/production-over-time?days=$days');
    return rows
        .map((r) {
          final map = Map<String, dynamic>.from(r as Map);
          final day = map['day'] as String;
          final total = (map['total'] as num?)?.toDouble() ?? 0;
          return TimeSeriesPoint(date: DateTime.parse('${day}T00:00:00.000'), value: total);
        })
        .toList(growable: false);
  }

  Future<List<DualTimeSeriesPoint>> getCostsVsProduction({int days = 30}) async {
    final rows = await _client.getJsonList('/api/dashboard/costs-vs-production?days=$days');
    return rows
        .map((r) {
          final map = Map<String, dynamic>.from(r as Map);
          final day = map['day'] as String;
          return DualTimeSeriesPoint(
            date: DateTime.parse('${day}T00:00:00.000'),
            a: (map['costo'] as num?)?.toDouble() ?? 0,
            b: (map['produccion'] as num?)?.toDouble() ?? 0,
          );
        })
        .toList(growable: false);
  }
}
