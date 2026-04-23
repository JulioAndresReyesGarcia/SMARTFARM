class RegistroProduccion {
  final int id;
  final int animalId;
  final DateTime fecha;
  final double produccion;

  const RegistroProduccion({
    required this.id,
    required this.animalId,
    required this.fecha,
    required this.produccion,
  });

  factory RegistroProduccion.fromMap(Map<String, Object?> map) {
    return RegistroProduccion(
      id: (map['id'] as num).toInt(),
      animalId: (map['animal_id'] as num).toInt(),
      fecha: DateTime.parse(map['fecha'] as String),
      produccion: (map['produccion'] as num).toDouble(),
    );
  }

  Map<String, Object?> toInsertMap() {
    return {
      'animal_id': animalId,
      'fecha': fecha.toIso8601String(),
      'produccion': produccion,
    };
  }
}

