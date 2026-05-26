import 'package:smartfarm_ai/core/config/app_config.dart';
import 'package:smartfarm_ai/data/local/analytics_local.dart';
import 'package:smartfarm_ai/models/time_series.dart';
import 'package:smartfarm_ai/services/remote/produccion_api_service.dart';
import 'package:smartfarm_ai/services/remote/raciones_api_service.dart';
import 'package:smartfarm_ai/services/remote/costos_api_service.dart';

class AnalyticsRepository {
  AnalyticsRepository({
    AnalyticsLocalDataSource? local,
    ProduccionApiService? produccionApi,
    RacionesApiService? racionesApi,
    CostosApiService? costosApi,
  })  : _local = local ?? AnalyticsLocalDataSource(),
        _produccionApi = produccionApi ?? ProduccionApiService(),
        _racionesApi = racionesApi ?? RacionesApiService(),
        _costosApi = costosApi ?? CostosApiService();

  final AnalyticsLocalDataSource _local;
  final ProduccionApiService _produccionApi;
  final RacionesApiService _racionesApi;
  final CostosApiService _costosApi;

  Future<List<TimeSeriesPoint>> getAnimalProductionSeries(int animalId, {int days = 30}) async {
    if (!AppConfig.useRemoteBackend) {
      return _local.getAnimalProductionSeries(animalId, days: days);
    }

    final rows = await _produccionApi.getForAnimal(animalId);
    final byDay = <String, double>{};
    for (final row in rows) {
      final day = row.fecha.toIso8601String().substring(0, 10);
      byDay[day] = (byDay[day] ?? 0) + row.produccion;
    }
    final sorted = byDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final limited = sorted.length > days ? sorted.sublist(sorted.length - days) : sorted;
    return limited
        .map((e) => TimeSeriesPoint(
              date: DateTime.parse('${e.key}T00:00:00.000'),
              value: e.value,
            ))
        .toList(growable: false);
  }

  Future<DualTimeSeriesPoint?> getAnimalFeedingVsProductionPoint(int animalId, {int days = 14}) async {
    if (!AppConfig.useRemoteBackend) {
      return _local.getAnimalFeedingVsProductionPoint(animalId, days: days);
    }

    final cutoff = DateTime.now().subtract(Duration(days: days));
    final produccion = await _produccionApi.getForAnimal(animalId);
    final raciones = await _racionesApi.getForAnimal(animalId);

    final prodValues = produccion.where((p) => p.fecha.isAfter(cutoff)).map((p) => p.produccion).toList();
    final feedValues = raciones.where((r) => r.fecha.isAfter(cutoff)).map((r) => r.cantidad).toList();

    if (prodValues.isEmpty && feedValues.isEmpty) return null;

    double avg(List<double> values) =>
        values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;

    return DualTimeSeriesPoint(date: DateTime.now(), a: avg(feedValues), b: avg(prodValues));
  }

  Future<List<double>> loadDoubles({
    required String table,
    required int animalId,
    required String field,
    int limit = 30,
  }) async {
    if (!AppConfig.useRemoteBackend) {
      return _local.loadDoubles(table: table, animalId: animalId, field: field, limit: limit);
    }

    if (table == 'registros_produccion' && field == 'produccion') {
      final rows = await _produccionApi.getForAnimal(animalId);
      return rows.take(limit).map((r) => r.produccion).toList(growable: false);
    }
    if (table == 'raciones' && field == 'cantidad') {
      final rows = await _racionesApi.getForAnimal(animalId);
      return rows.take(limit).map((r) => r.cantidad).toList(growable: false);
    }
    if (table == 'costos_alimentacion' && field == 'costo') {
      final rows = await _costosApi.getForAnimal(animalId);
      return rows.take(limit).map((r) => r.costo).toList(growable: false);
    }
    return [];
  }

  Future<List<String>> loadStrings({
    required String table,
    required int animalId,
    required String field,
    int limit = 30,
  }) async {
    if (!AppConfig.useRemoteBackend) {
      return _local.loadStrings(table: table, animalId: animalId, field: field, limit: limit);
    }

    if (table == 'raciones' && field == 'tipo_alimento') {
      final rows = await _racionesApi.getForAnimal(animalId);
      return rows.take(limit).map((r) => r.tipoAlimento).toList(growable: false);
    }
    return [];
  }
}
