import 'dart:math';

import 'package:sqflite/sqflite.dart';
import 'package:smartfarm_ai/database/app_database.dart';

class DemoDataService {
  Future<void> seedIfEmpty({int days = 30}) async {
    final db = await AppDatabase.instance.database;
    final prodCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM registros_produccion')) ?? 0;
    final rCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM raciones')) ?? 0;
    final cCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM costos_alimentacion')) ?? 0;
    if (prodCount > 0 || rCount > 0 || cCount > 0) return;

    final animals = await db.query('animales', columns: ['id', 'peso', 'tipo', 'edad'], orderBy: 'id ASC');
    if (animals.isEmpty) return;

    final rand = Random(7);

    DateTime day(int daysAgo) {
      final d = DateTime.now().subtract(Duration(days: daysAgo));
      return DateTime(d.year, d.month, d.day, 8);
    }

    Future<void> prod(int animalId, DateTime fecha, double v) async {
      await db.insert('registros_produccion', {
        'animal_id': animalId,
        'fecha': fecha.toIso8601String(),
        'produccion': v,
      });
    }

    Future<void> racion(int animalId, DateTime fecha, double kg, String tipo) async {
      await db.insert('raciones', {
        'animal_id': animalId,
        'fecha': fecha.toIso8601String(),
        'cantidad': kg,
        'tipo_alimento': tipo,
      });
    }

    Future<void> costo(int animalId, DateTime fecha, double v) async {
      await db.insert('costos_alimentacion', {
        'animal_id': animalId,
        'costo': v,
        'fecha': fecha.toIso8601String(),
      });
    }

    for (var i = days - 1; i >= 0; i--) {
      final fecha = day(i);
      for (final a in animals) {
        final id = (a['id'] as num).toInt();
        final peso = (a['peso'] as num).toDouble();
        final tipo = (a['tipo'] as String?) ?? '';

        final baseProd = tipo.toLowerCase().contains('capr') ? 3.2 : (peso > 420 ? 10.5 : 7.0);
        final baseKg = (peso * 0.025).clamp(0.8, 18.0);
        final prodV = baseProd + rand.nextDouble() * (tipo.toLowerCase().contains('capr') ? 1.2 : 2.8);
        final kgV = baseKg + (rand.nextDouble() * 1.2) - 0.2;
        final costV = (kgV * (tipo.toLowerCase().contains('capr') ? 2.2 : 2.6)) + rand.nextDouble() * 4.5;

        await prod(id, fecha, double.parse(prodV.toStringAsFixed(2)));
        await racion(
          id,
          fecha,
          double.parse(kgV.toStringAsFixed(2)),
          tipo.toLowerCase().contains('capr') ? 'Forraje de calidad' : (peso > 420 ? 'Alto en proteína' : 'Balanceado'),
        );
        await costo(id, fecha, double.parse(costV.toStringAsFixed(2)));
      }
    }
  }
}

