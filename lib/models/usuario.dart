class Usuario {
  final int id;
  final String nombre;
  final String email;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
  });

  factory Usuario.fromMap(Map<String, Object?> map) {
    return Usuario(
      id: (map['id'] as num).toInt(),
      nombre: (map['nombre'] as String),
      email: (map['email'] as String),
    );
  }
}

