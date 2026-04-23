class Recomendacion {
  final int id;
  final int animalId;
  final String recomendacion;
  final DateTime fecha;

  const Recomendacion({
    required this.id,
    required this.animalId,
    required this.recomendacion,
    required this.fecha,
  });

  factory Recomendacion.fromMap(Map<String, Object?> map) {
    return Recomendacion(
      id: (map['id'] as num).toInt(),
      animalId: (map['animal_id'] as num).toInt(),
      recomendacion: map['recomendacion'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
    );
  }

  Map<String, Object?> toInsertMap() {
    return {
      'animal_id': animalId,
      'recomendacion': recomendacion,
      'fecha': fecha.toIso8601String(),
    };
  }
}

