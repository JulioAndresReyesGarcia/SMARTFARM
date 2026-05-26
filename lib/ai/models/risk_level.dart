/// Nivel de riesgo orientativo (no es un diagnóstico clínico).
enum RiskLevel {
  bajo('Bajo', 'Seguimiento rutinario'),
  medio('Medio', 'Vigilar de cerca; consultar si empeora'),
  alto('Alto', 'Consulta veterinaria pronto'),
  emergencia('Emergencia', 'Atención veterinaria inmediata');

  const RiskLevel(this.label, this.actionHint);
  final String label;
  final String actionHint;
}
