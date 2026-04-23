class CostoAlimentacion {
  final int id;
  final int animalId;
  final double costo;
  final DateTime fecha;

  const CostoAlimentacion({
    required this.id,
    required this.animalId,
    required this.costo,
    required this.fecha,
  });

  factory CostoAlimentacion.fromMap(Map<String, Object?> map) {
    return CostoAlimentacion(
      id: (map['id'] as num).toInt(),
      animalId: (map['animal_id'] as num).toInt(),
      costo: (map['costo'] as num).toDouble(),
      fecha: DateTime.parse(map['fecha'] as String),
    );
  }

  Map<String, Object?> toInsertMap() {
    return {
      'animal_id': animalId,
      'costo': costo,
      'fecha': fecha.toIso8601String(),
    };
  }
}

