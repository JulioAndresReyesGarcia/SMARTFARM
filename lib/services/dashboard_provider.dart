import 'package:flutter/foundation.dart';

import 'package:sqflite/sqflite.dart';
import 'package:smartfarm_ai/database/app_database.dart';

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
  bool _busy = false;

  DashboardStats? get stats => _stats;
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
      notifyListeners();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}

