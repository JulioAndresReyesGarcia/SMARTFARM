import 'package:flutter/foundation.dart';

import 'package:smartfarm_ai/models/animal.dart';
import 'package:smartfarm_ai/models/time_series.dart';
import 'package:smartfarm_ai/services/analytics_service.dart';
import 'package:smartfarm_ai/services/animales_service.dart';
import 'package:smartfarm_ai/services/recomendaciones_service.dart';

class AnimalsProvider extends ChangeNotifier {
  final AnimalesService _service = AnimalesService();
  final AnalyticsService _analytics = AnalyticsService();
  final RecomendacionesService _recomendaciones = RecomendacionesService();

  List<Animal> _items = const [];
  Map<int, String> _recommendationBadges = const {};
  bool _busy = false;
  String? _error;

  List<Animal> get items => _items;
  Map<int, String> get recommendationBadges => _recommendationBadges;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> refresh() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.getAll();
      _recommendationBadges = await _recomendaciones.getLatestBadgesForAnimals(_items.map((a) => a.id).toList());
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<Animal> create({
    required String nombre,
    required double peso,
    required int edad,
    required String tipo,
  }) async {
    try {
      final created = await _service.create(nombre: nombre, peso: peso, edad: edad, tipo: tipo);
      await refresh();
      return created;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(Animal animal) async {
    try {
      await _service.update(animal);
      await refresh();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _service.delete(id);
      await refresh();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<TimeSeriesPoint>> getAnimalProductionSeries(int animalId, {int days = 30}) {
    return _analytics.getAnimalProductionSeries(animalId, days: days);
  }

  Future<DualTimeSeriesPoint?> getAnimalFeedingVsProductionPoint(int animalId, {int days = 14}) {
    return _analytics.getAnimalFeedingVsProductionPoint(animalId, days: days);
  }
}
