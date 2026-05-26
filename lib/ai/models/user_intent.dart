/// Intención detectada en la consulta del usuario.
enum UserIntent {
  sintomas('Síntomas / salud'),
  nutricion('Nutrición / alimentación'),
  produccion('Producción'),
  vacunacion('Vacunación'),
  reproduccion('Reproducción'),
  comportamiento('Comportamiento'),
  clima('Clima / ambiente'),
  higiene('Higiene / bioseguridad'),
  emergencia('Emergencia'),
  veterinario('Buscar veterinario'),
  general('Consulta general');

  const UserIntent(this.label);
  final String label;
}
