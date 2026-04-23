class Racion {
  final int id;
  final int animalId;
  final DateTime fecha;
  final double cantidad;
  final String tipoAlimento;

  const Racion({
    required this.id,
    required this.animalId,
    required this.fecha,
    required this.cantidad,
    required this.tipoAlimento,
  });

  factory Racion.fromMap(Map<String, Object?> map) {
    return Racion(
      id: (map['id'] as num).toInt(),
      animalId: (map['animal_id'] as num).toInt(),
      fecha: DateTime.parse(map['fecha'] as String),
      cantidad: (map['cantidad'] as num).toDouble(),
      tipoAlimento: map['tipo_alimento'] as String,
    );
  }

  Map<String, Object?> toInsertMap() {
    return {
      'animal_id': animalId,
      'fecha': fecha.toIso8601String(),
      'cantidad': cantidad,
      'tipo_alimento': tipoAlimento,
    };
  }
}

