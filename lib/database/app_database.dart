import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final created = await _open();
    _db = created;
    return created;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'smartfarm_ai.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seed(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
CREATE TABLE usuarios (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE animales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  peso REAL NOT NULL,
  edad INTEGER NOT NULL,
  tipo TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE raciones (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  animal_id INTEGER NOT NULL,
  fecha TEXT NOT NULL,
  cantidad REAL NOT NULL,
  tipo_alimento TEXT NOT NULL,
  FOREIGN KEY (animal_id) REFERENCES animales (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE recomendaciones (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  animal_id INTEGER NOT NULL,
  recomendacion TEXT NOT NULL,
  fecha TEXT NOT NULL,
  FOREIGN KEY (animal_id) REFERENCES animales (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE registros_produccion (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  animal_id INTEGER NOT NULL,
  fecha TEXT NOT NULL,
  produccion REAL NOT NULL,
  FOREIGN KEY (animal_id) REFERENCES animales (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE costos_alimentacion (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  animal_id INTEGER NOT NULL,
  costo REAL NOT NULL,
  fecha TEXT NOT NULL,
  FOREIGN KEY (animal_id) REFERENCES animales (id) ON DELETE CASCADE
)
''');
  }

  Future<void> _seed(Database db) async {
    await db.insert('usuarios', {
      'nombre': 'Administrador',
      'email': 'admin@smartfarm.ai',
      'password': '1234',
    });

    final a1 = await db.insert('animales', {
      'nombre': 'Luna',
      'peso': 280.0,
      'edad': 18,
      'tipo': 'Bovino',
    });
    final a2 = await db.insert('animales', {
      'nombre': 'ToroMax',
      'peso': 450.0,
      'edad': 36,
      'tipo': 'Bovino',
    });
    final a3 = await db.insert('animales', {
      'nombre': 'Nube',
      'peso': 340.0,
      'edad': 24,
      'tipo': 'Caprino',
    });

    final now = DateTime.now().toIso8601String();
    Future<void> rec(int animalId, String text) async {
      await db.insert('recomendaciones', {
        'animal_id': animalId,
        'recomendacion': text,
        'fecha': now,
      });
    }

    await rec(a1, 'Dieta de engorde: aumentar energía y carbohidratos de calidad.');
    await rec(a2, 'Dieta alta en proteína: priorizar fuentes proteicas y balance mineral.');
    await rec(a3, 'Dieta balanceada: mantener proporción adecuada de energía y proteína.');
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }
}

