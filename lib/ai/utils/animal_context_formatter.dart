import 'package:smartfarm_ai/ai/knowledge/livestock_knowledge.dart';

/// Utilidades para anclar respuestas al animal seleccionado.
class AnimalContextFormatter {
  AnimalContextFormatter._();

  static String label({required String nombre, required String tipo}) {
    final n = nombre.trim();
    if (n.isNotEmpty) return '$n ($tipo)';
    return tipo;
  }

  static String fullLabel({
    required String nombre,
    required String tipo,
    required double pesoKg,
    required int edadMeses,
  }) {
    final base = label(nombre: nombre, tipo: tipo);
    return '$base · ${pesoKg.toStringAsFixed(0)} kg · $edadMeses meses';
  }

  /// Prefija la consulta con datos del animal para que la IA no se desvíe.
  static String anchorQuestion({
    required String nombre,
    required String tipo,
    required double pesoKg,
    required int edadMeses,
    required String question,
  }) {
    final full = fullLabel(nombre: nombre, tipo: tipo, pesoKg: pesoKg, edadMeses: edadMeses);
    final guidance = LivestockKnowledge.speciesGuidance(tipo);
    return 'Consulta sobre el animal registrado: $full.\n'
        'Perfil de especie: $guidance\n'
        'Pregunta del productor: ${question.trim()}';
  }

  /// Etiqueta mensajes del historial para no mezclar animales.
  static String tagHistoryMessage({
    required String nombre,
    required String tipo,
    required String content,
  }) {
    final tag = label(nombre: nombre, tipo: tipo);
    return '[$tag] $content';
  }

  static bool historyMatchesAnimal(String content, String nombre, String tipo) {
    final tag = label(nombre: nombre, tipo: tipo);
    return content.startsWith('[$tag]');
  }

  static String stripHistoryTag(String content) {
    final end = content.indexOf('] ');
    if (content.startsWith('[') && end > 0) {
      return content.substring(end + 2);
    }
    return content;
  }
}
