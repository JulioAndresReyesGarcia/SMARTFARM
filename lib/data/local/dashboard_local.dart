import 'package:sqflite/sqflite.dart';

import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/models/dashboard_stats.dart';
import 'package:smartfarm_ai/models/time_series.dart';

class DashboardLocalDataSource {
  Future<DashboardStats> getStats() async {
    final db = await AppDatabase.instance.database;
    final animales = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM animales')) ?? 0;
    final raciones = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM raciones')) ?? 0;
    final produccion = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM registros_produccion')) ?? 0;
    final costos = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM costos_alimentacion')) ?? 0;
    return DashboardStats(
      animales: animales,
      raciones: raciones,
      produccion: produccion,
      costos: costos,
    );
  }

  Future<List<TimeSeriesPoint>> getProductionOverTime({int days = 30}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
SELECT substr(fecha, 1, 10) AS day, SUM(produccion) AS total
FROM registros_produccion
GROUP BY day
ORDER BY day DESC
LIMIT ?
''', [days]);

    return rows
        .map((r) {
          final day = r['day'] as String;
          final total = (r['total'] as num?)?.toDouble() ?? 0;
          return TimeSeriesPoint(date: DateTime.parse('${day}T00:00:00.000'), value: total);
        })
        .toList(growable: false)
        .reversed
        .toList(growable: false);
  }

  Future<List<DualTimeSeriesPoint>> getCostsVsProduction({int days = 30}) async {
    final db = await AppDatabase.instance.database;
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

    return rows
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
  }
}
