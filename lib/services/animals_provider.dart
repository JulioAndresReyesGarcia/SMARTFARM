import 'package:flutter/foundation.dart';

import 'package:smartfarm_ai/models/animal.dart';
import 'package:smartfarm_ai/models/time_series.dart';
import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/services/animales_service.dart';

class AnimalsProvider extends ChangeNotifier {
  final AnimalesService _service = AnimalesService();

  List<Animal> _items = const [];
  bool _busy = false;

  List<Animal> get items => _items;
  bool get busy => _busy;

  Future<void> refresh() async {
    _busy = true;
    notifyListeners();
    try {
      _items = await _service.getAll();
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<int> create({
    required String nombre,
    required double peso,
    required int edad,
    required String tipo,
  }) async {
    final id = await _service.create(nombre: nombre, peso: peso, edad: edad, tipo: tipo);
    await refresh();
    return id;
  }

  Future<void> update(Animal animal) async {
    await _service.update(animal);
    await refresh();
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    await refresh();
  }

  Future<List<TimeSeriesPoint>> getAnimalProductionSeries(int animalId, {int days = 30}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
SELECT substr(fecha, 1, 10) AS day, SUM(produccion) AS total
FROM registros_produccion
WHERE animal_id = ?
GROUP BY day
ORDER BY day DESC
LIMIT ?
''', [animalId, days]);

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

  Future<DualTimeSeriesPoint?> getAnimalFeedingVsProductionPoint(int animalId, {int days = 14}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
WITH p AS (
  SELECT AVG(produccion) AS v
  FROM registros_produccion
  WHERE animal_id = ? AND fecha >= datetime('now', ?)
),
f AS (
  SELECT AVG(cantidad) AS v
  FROM raciones
  WHERE animal_id = ? AND fecha >= datetime('now', ?)
)
SELECT COALESCE(f.v, 0) AS feed, COALESCE(p.v, 0) AS prod
FROM p, f
''', [animalId, '-$days day', animalId, '-$days day']);

    if (rows.isEmpty) return null;
    final r = rows.first;
    final feed = (r['feed'] as num?)?.toDouble() ?? 0;
    final prod = (r['prod'] as num?)?.toDouble() ?? 0;
    return DualTimeSeriesPoint(date: DateTime.now(), a: feed, b: prod);
  }
}

