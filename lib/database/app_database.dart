import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:smartfarm_ai/database/database_seeder.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String dbFileName = 'app_data.db';
  static const int dbVersion = 2;

  Database? _db;
  Completer<void>? _initCompleter;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final created = await _open();
    _db = created;
    return created;
  }

  Future<void> initialize() async {
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();
    try {
      await database;
      _initCompleter!.complete();
    } catch (e, st) {
      _initCompleter!.completeError(e, st);
      _initCompleter = null;
      _db = null;
      rethrow;
    }
  }

  /// Seed en segundo plano para no bloquear el arranque de la UI.
  Future<void> seedInBackground() async {
    try {
      await DatabaseSeeder.instance.seedIfNeeded();
    } catch (_) {
      // El seed puede reintentarse desde el dashboard.
    }
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, dbFileName);
    await _migrateLegacyDatabase(dir.path, path);

    try {
      return await _openDatabaseAt(path);
    } catch (_) {
      await _deleteDatabaseFile(path);
      await _deleteDatabaseFile(p.join(dir.path, 'smartfarm_ai.db'));
      return _openDatabaseAt(path);
    }
  }

  Future<Database> _openDatabaseAt(String path) {
    return openDatabase(
      path,
      version: dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _upgradeToV2(db);
        }
      },
    );
  }

  Future<void> _deleteDatabaseFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
      final journal = File('$path-journal');
      if (await journal.exists()) await journal.delete();
      final wal = File('$path-wal');
      if (await wal.exists()) await wal.delete();
    } catch (_) {}
  }

  Future<void> _migrateLegacyDatabase(String dirPath, String newPath) async {
    final legacyPath = p.join(dirPath, 'smartfarm_ai.db');
    final legacyFile = File(legacyPath);
    final newFile = File(newPath);
    if (!await newFile.exists() && await legacyFile.exists()) {
      await legacyFile.copy(newPath);
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
CREATE TABLE migrations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  applied_at TEXT NOT NULL DEFAULT (datetime('current_timestamp'))
)
''');

    await db.execute('''
CREATE TABLE usuarios (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('current_timestamp')),
  updated_at TEXT NOT NULL DEFAULT (datetime('current_timestamp'))
)
''');

    await db.execute('''
CREATE TABLE animales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  peso REAL NOT NULL,
  edad INTEGER NOT NULL,
  tipo TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('current_timestamp')),
  updated_at TEXT NOT NULL DEFAULT (datetime('current_timestamp'))
)
''');

    await db.execute('''
CREATE TABLE raciones (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  animal_id INTEGER NOT NULL,
  fecha TEXT NOT NULL,
  cantidad REAL NOT NULL,
  tipo_alimento TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('current_timestamp')),
  updated_at TEXT NOT NULL DEFAULT (datetime('current_timestamp')),
  FOREIGN KEY (animal_id) REFERENCES animales (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE recomendaciones (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  animal_id INTEGER NOT NULL,
  recomendacion TEXT NOT NULL,
  fecha TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('current_timestamp')),
  updated_at TEXT NOT NULL DEFAULT (datetime('current_timestamp')),
  FOREIGN KEY (animal_id) REFERENCES animales (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE registros_produccion (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  animal_id INTEGER NOT NULL,
  fecha TEXT NOT NULL,
  produccion REAL NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('current_timestamp')),
  updated_at TEXT NOT NULL DEFAULT (datetime('current_timestamp')),
  FOREIGN KEY (animal_id) REFERENCES animales (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE costos_alimentacion (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  animal_id INTEGER NOT NULL,
  costo REAL NOT NULL,
  fecha TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('current_timestamp')),
  updated_at TEXT NOT NULL DEFAULT (datetime('current_timestamp')),
  FOREIGN KEY (animal_id) REFERENCES animales (id) ON DELETE CASCADE
)
''');

    await _createIndexes(db);
    await _insertMigration(db, 'schema_v2');
  }

  Future<void> _upgradeToV2(Database db) async {
    final applied = Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='migrations'"),
        ) ??
        0;

    if (applied == 0) {
      await db.execute('''
CREATE TABLE migrations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  applied_at TEXT NOT NULL DEFAULT (datetime('current_timestamp'))
)
''');
    }

    const tables = [
      'usuarios',
      'animales',
      'raciones',
      'recomendaciones',
      'registros_produccion',
      'costos_alimentacion',
    ];

    for (final table in tables) {
      final columns = await db.rawQuery('PRAGMA table_info($table)');
      final names = columns.map((c) => c['name'] as String).toSet();
      if (!names.contains('created_at')) {
        await db.execute(
          "ALTER TABLE $table ADD COLUMN created_at TEXT NOT NULL DEFAULT (datetime('current_timestamp'))",
        );
      }
      if (!names.contains('updated_at')) {
        await db.execute(
          "ALTER TABLE $table ADD COLUMN updated_at TEXT NOT NULL DEFAULT (datetime('current_timestamp'))",
        );
      }
    }

    await _createIndexes(db);
    await _insertMigration(db, 'schema_v2', ignore: true);
  }

  Future<void> _insertMigration(Database db, String name, {bool ignore = false}) async {
    final row = {
      'name': name,
      'applied_at': DateTime.now().toIso8601String(),
    };
    if (ignore) {
      await db.insert('migrations', row, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.insert('migrations', row);
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios (email)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_animales_tipo ON animales (tipo)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_raciones_animal_fecha ON raciones (animal_id, fecha DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_recomendaciones_animal_fecha ON recomendaciones (animal_id, fecha DESC)');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_registros_produccion_animal_fecha ON registros_produccion (animal_id, fecha DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_costos_alimentacion_animal_fecha ON costos_alimentacion (animal_id, fecha DESC)',
    );
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    _initCompleter = null;
    await db?.close();
  }
}
