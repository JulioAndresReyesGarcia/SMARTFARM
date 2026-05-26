import 'dart:math';

import 'package:sqflite/sqflite.dart';
import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/database/db_helpers.dart';

class DatabaseSeeder {
  DatabaseSeeder._();

  static final DatabaseSeeder instance = DatabaseSeeder._();

  static const _seedMigration = 'seed_initial_data_v1';

  static const demoEmail = 'admin@smartfarm.ai';
  static const demoPassword = '1234';

  /// Garantiza el usuario demo antes del login (rápido, síncrono).
  Future<void> ensureDemoUser() async {
    final db = await AppDatabase.instance.database;
    final userCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM usuarios')) ?? 0;
    if (userCount == 0) {
      await _seedUsers(db);
    }
  }

  Future<void> seedIfNeeded() async {
    final db = await AppDatabase.instance.database;

    // Siempre verificar usuario demo aunque el seed completo ya se haya marcado.
    await ensureDemoUser();

    if (await _isApplied(db, _seedMigration)) return;

    final animalCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM animales')) ?? 0;
    if (animalCount == 0) {
      await _seedAnimalsAndHistory(db);
    } else {
      await _seedHistoryIfEmpty(db);
    }

    await _markApplied(db, _seedMigration);
  }

  Future<void> seedDemoHistory({int days = 30}) async {
    final db = await AppDatabase.instance.database;
    await _seedHistoryIfEmpty(db, days: days);
  }

  Future<bool> _isApplied(Database db, String name) async {
    final rows = await db.query('migrations', where: 'name = ?', whereArgs: [name], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> _markApplied(Database db, String name) async {
    await db.insert(
      'migrations',
      {'name': name, 'applied_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _seedUsers(Database db) async {
    await db.insert('usuarios', withDbTimestamps({
      'nombre': 'Administrador',
      'email': demoEmail,
      'password': demoPassword,
    }));
  }

  Future<void> _seedAnimalsAndHistory(Database db) async {
    final a1 = await db.insert('animales', withDbTimestamps({
      'nombre': 'Luna',
      'peso': 280.0,
      'edad': 18,
      'tipo': 'Bovino',
    }));
    final a2 = await db.insert('animales', withDbTimestamps({
      'nombre': 'ToroMax',
      'peso': 450.0,
      'edad': 36,
      'tipo': 'Bovino',
    }));
    final a3 = await db.insert('animales', withDbTimestamps({
      'nombre': 'Nube',
      'peso': 340.0,
      'edad': 24,
      'tipo': 'Caprino',
    }));

    final now = DateTime.now().toIso8601String();
    await db.insert('recomendaciones', withDbTimestamps({
      'animal_id': a1,
      'recomendacion': 'Dieta de engorde: aumentar energía y carbohidratos de calidad.',
      'fecha': now,
    }));
    await db.insert('recomendaciones', withDbTimestamps({
      'animal_id': a2,
      'recomendacion': 'Dieta alta en proteína: priorizar fuentes proteicas y balance mineral.',
      'fecha': now,
    }));
    await db.insert('recomendaciones', withDbTimestamps({
      'animal_id': a3,
      'recomendacion': 'Dieta balanceada: mantener proporción adecuada de energía y proteína.',
      'fecha': now,
    }));

    await _insertHistoryForAnimals(db, [
      {'id': a1, 'peso': 280.0, 'tipo': 'Bovino', 'edad': 18},
      {'id': a2, 'peso': 450.0, 'tipo': 'Bovino', 'edad': 36},
      {'id': a3, 'peso': 340.0, 'tipo': 'Caprino', 'edad': 24},
    ], days: 30);
  }

  Future<void> _seedHistoryIfEmpty(Database db, {int days = 30}) async {
    final prodCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM registros_produccion')) ?? 0;
    final rCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM raciones')) ?? 0;
    final cCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM costos_alimentacion')) ?? 0;
    if (prodCount > 0 || rCount > 0 || cCount > 0) return;

    final animals = await db.query('animales', columns: ['id', 'peso', 'tipo', 'edad'], orderBy: 'id ASC');
    if (animals.isEmpty) return;
    await _insertHistoryForAnimals(db, animals, days: days);
  }

  Future<void> _insertHistoryForAnimals(
    Database db,
    List<Map<String, Object?>> animals, {
    required int days,
  }) async {
    final rand = Random(7);

    DateTime day(int daysAgo) {
      final d = DateTime.now().subtract(Duration(days: daysAgo));
      return DateTime(d.year, d.month, d.day, 8);
    }

    for (var i = days - 1; i >= 0; i--) {
      final fecha = day(i);
      for (final a in animals) {
        final id = (a['id'] as num).toInt();
        final peso = (a['peso'] as num).toDouble();
        final tipo = (a['tipo'] as String?) ?? '';
        final isCapr = tipo.toLowerCase().contains('capr');

        final baseProd = isCapr ? 3.2 : (peso > 420 ? 10.5 : 7.0);
        final baseKg = (peso * 0.025).clamp(0.8, 18.0);
        final prodV = baseProd + rand.nextDouble() * (isCapr ? 1.2 : 2.8);
        final kgV = baseKg + (rand.nextDouble() * 1.2) - 0.2;
        final costV = (kgV * (isCapr ? 2.2 : 2.6)) + rand.nextDouble() * 4.5;

        await db.insert('registros_produccion', withDbTimestamps({
          'animal_id': id,
          'fecha': fecha.toIso8601String(),
          'produccion': double.parse(prodV.toStringAsFixed(2)),
        }));
        await db.insert('raciones', withDbTimestamps({
          'animal_id': id,
          'fecha': fecha.toIso8601String(),
          'cantidad': double.parse(kgV.toStringAsFixed(2)),
          'tipo_alimento': isCapr
              ? 'Forraje de calidad'
              : (peso > 420 ? 'Alto en proteína' : 'Balanceado'),
        }));
        await db.insert('costos_alimentacion', withDbTimestamps({
          'animal_id': id,
          'costo': double.parse(costV.toStringAsFixed(2)),
          'fecha': fecha.toIso8601String(),
        }));
      }
    }
  }
}
