import 'package:flutter/foundation.dart';

import 'package:smartfarm_ai/models/animal.dart';
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
}

