/// Android SQLite no aplica DEFAULT en columnas NOT NULL al omitirlas en INSERT.
/// Usar este helper en todos los inserts.
Map<String, Object?> withDbTimestamps(Map<String, Object?> data) {
  final now = DateTime.now().toIso8601String();
  return {
    ...data,
    if (!data.containsKey('created_at')) 'created_at': now,
    if (!data.containsKey('updated_at')) 'updated_at': now,
  };
}

String dbNow() => DateTime.now().toIso8601String();
