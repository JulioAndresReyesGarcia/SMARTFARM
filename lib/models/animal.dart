class Animal {
  final int id;
  final String nombre;
  final double peso;
  final int edad;
  final String tipo;

  const Animal({
    required this.id,
    required this.nombre,
    required this.peso,
    required this.edad,
    required this.tipo,
  });

  factory Animal.fromMap(Map<String, Object?> map) {
    return Animal(
      id: (map['id'] as num).toInt(),
      nombre: map['nombre'] as String,
      peso: (map['peso'] as num).toDouble(),
      edad: (map['edad'] as num).toInt(),
      tipo: map['tipo'] as String,
    );
  }

  Map<String, Object?> toInsertMap() {
    return {
      'nombre': nombre,
      'peso': peso,
      'edad': edad,
      'tipo': tipo,
    };
  }

  Map<String, Object?> toUpdateMap() {
    return {
      'id': id,
      'nombre': nombre,
      'peso': peso,
      'edad': edad,
      'tipo': tipo,
    };
  }
}

