import 'package:flutter/foundation.dart';

import 'package:smartfarm_ai/models/dashboard_stats.dart';
import 'package:smartfarm_ai/models/time_series.dart';
import 'package:smartfarm_ai/services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();

  DashboardStats? _stats;
  List<TimeSeriesPoint> _productionOverTime = const [];
  List<DualTimeSeriesPoint> _costsVsProduction = const [];
  bool _busy = false;
  String? _error;

  DashboardStats? get stats => _stats;
  List<TimeSeriesPoint> get productionOverTime => _productionOverTime;
  List<DualTimeSeriesPoint> get costsVsProduction => _costsVsProduction;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> refresh() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _stats = await _service.getStats();
      _productionOverTime = await _service.getProductionOverTime(days: 30);
      _costsVsProduction = await _service.getCostsVsProduction(days: 30);
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
