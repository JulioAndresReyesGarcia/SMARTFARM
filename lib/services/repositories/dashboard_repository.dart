import 'package:smartfarm_ai/core/config/app_config.dart';
import 'package:smartfarm_ai/data/local/dashboard_local.dart';
import 'package:smartfarm_ai/models/dashboard_stats.dart';
import 'package:smartfarm_ai/models/time_series.dart';
import 'package:smartfarm_ai/services/remote/dashboard_api_service.dart';

class DashboardRepository {
  DashboardRepository({
    DashboardLocalDataSource? local,
    DashboardApiService? remote,
  })  : _local = local ?? DashboardLocalDataSource(),
        _remote = remote ?? DashboardApiService();

  final DashboardLocalDataSource _local;
  final DashboardApiService _remote;

  Future<DashboardStats> getStats() {
    return AppConfig.useRemoteBackend ? _remote.getStats() : _local.getStats();
  }

  Future<List<TimeSeriesPoint>> getProductionOverTime({int days = 30}) {
    return AppConfig.useRemoteBackend
        ? _remote.getProductionOverTime(days: days)
        : _local.getProductionOverTime(days: days);
  }

  Future<List<DualTimeSeriesPoint>> getCostsVsProduction({int days = 30}) {
    return AppConfig.useRemoteBackend
        ? _remote.getCostsVsProduction(days: days)
        : _local.getCostsVsProduction(days: days);
  }
}
