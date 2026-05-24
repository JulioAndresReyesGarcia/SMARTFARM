import 'package:flutter/foundation.dart';

import 'package:sqflite/sqflite.dart';
import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/models/time_series.dart';

class DashboardStats {
  final int animales;
  final int raciones;
  final int produccion;
  final int costos;

  const DashboardStats({
    required this.animales,
    required this.raciones,
    required this.produccion,
    required this.costos,
  });
}

class DashboardProvider extends ChangeNotifier {
  DashboardStats? _stats;
  List<TimeSeriesPoint> _productionOverTime = const [];
  List<DualTimeSeriesPoint> _costsVsProduction = const [];
  bool _busy = false;

  DashboardStats? get stats => _stats;
  List<TimeSeriesPoint> get productionOverTime => _productionOverTime;
  List<DualTimeSeriesPoint> get costsVsProduction => _costsVsProduction;
  bool get busy => _busy;

  Future<void> refresh() async {
    _busy = true;
    notifyListeners();
    try {
      final db = await AppDatabase.instance.database;
      final animales = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM animales')) ?? 0;
      final raciones = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM raciones')) ?? 0;
      final prod = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM registros_produccion')) ?? 0;
      final costos = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM costos_alimentacion')) ?? 0;
      _stats = DashboardStats(animales: animales, raciones: raciones, produccion: prod, costos: costos);
      _productionOverTime = await _loadProductionOverTime(db, days: 30);
      _costsVsProduction = await _loadCostsVsProduction(db, days: 30);
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<List<TimeSeriesPoint>> _loadProductionOverTime(Database db, {required int days}) async {
    final rows = await db.rawQuery('''
SELECT substr(fecha, 1, 10) AS day, SUM(produccion) AS total
FROM registros_produccion
GROUP BY day
ORDER BY day DESC
LIMIT ?
''', [days]);

    final points = rows
        .map((r) {
          final day = r['day'] as String;
          final total = (r['total'] as num?)?.toDouble() ?? 0;
          return TimeSeriesPoint(date: DateTime.parse('${day}T00:00:00.000'), value: total);
        })
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    return points;
  }

  Future<List<DualTimeSeriesPoint>> _loadCostsVsProduction(Database db, {required int days}) async {
    final rows = await db.rawQuery('''
WITH prod AS (
  SELECT substr(fecha, 1, 10) AS day, SUM(produccion) AS v
  FROM registros_produccion
  GROUP BY day
),
cost AS (
  SELECT substr(fecha, 1, 10) AS day, SUM(costo) AS v
  FROM costos_alimentacion
  GROUP BY day
)
SELECT COALESCE(prod.day, cost.day) AS day,
       COALESCE(cost.v, 0) AS costo,
       COALESCE(prod.v, 0) AS produccion
FROM prod
LEFT JOIN cost ON cost.day = prod.day
UNION
SELECT COALESCE(prod.day, cost.day) AS day,
       COALESCE(cost.v, 0) AS costo,
       COALESCE(prod.v, 0) AS produccion
FROM cost
LEFT JOIN prod ON prod.day = cost.day
ORDER BY day DESC
LIMIT ?
''', [days]);

    final points = rows
        .map((r) {
          final day = r['day'] as String;
          final costo = (r['costo'] as num?)?.toDouble() ?? 0;
          final prod = (r['produccion'] as num?)?.toDouble() ?? 0;
          return DualTimeSeriesPoint(
            date: DateTime.parse('${day}T00:00:00.000'),
            a: costo,
            b: prod,
          );
        })
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    return points;
  }
}

