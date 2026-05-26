import 'package:smartfarm_ai/ai/models/risk_level.dart';
import 'package:smartfarm_ai/ai/models/user_intent.dart';
import 'package:smartfarm_ai/ai/models/veterinarian_suggestion.dart';

/// Respuesta estructurada del asistente ganadero.
class AiAssistantResponse {
  final UserIntent intent;
  final RiskLevel riskLevel;
  final String summary;
  final String? probableAssessment;
  final List<String> recommendations;
  final List<String> prevention;
  final String whenToSeeVet;
  final List<VeterinarianSuggestion> veterinarians;
  final String disclaimer;
  final bool usedCloudAi;
  final String? cloudProviderName;
  /// Motivo por el que se usó fallback local pese a tener IA en la nube configurada.
  final String? cloudFallbackReason;
  final List<String> detectedSymptoms;

  const AiAssistantResponse({
    required this.intent,
    required this.riskLevel,
    required this.summary,
    this.probableAssessment,
    this.recommendations = const [],
    this.prevention = const [],
    required this.whenToSeeVet,
    this.veterinarians = const [],
    this.disclaimer = _defaultDisclaimer,
    this.usedCloudAi = false,
    this.cloudProviderName,
    this.cloudFallbackReason,
    this.detectedSymptoms = const [],
  });

  static const _defaultDisclaimer =
      'Orientación informativa. No sustituye diagnóstico ni tratamiento veterinario profesional.';

  /// Texto plano compatible con el chat anterior.
  String toDisplayText() {
    final buffer = StringBuffer();
    buffer.writeln(summary);
    if (probableAssessment != null && probableAssessment!.trim().isNotEmpty) {
      buffer.writeln('\nEvaluación orientativa: ${probableAssessment!.trim()}');
    }
    if (detectedSymptoms.isNotEmpty) {
      buffer.writeln('\nSíntomas detectados: ${detectedSymptoms.join(', ')}');
    }
    buffer.writeln('\nNivel de riesgo: ${riskLevel.label} — ${riskLevel.actionHint}');
    if (recommendations.isNotEmpty) {
      buffer.writeln('\nRecomendaciones:');
      for (final r in recommendations) {
        buffer.writeln('• $r');
      }
    }
    if (prevention.isNotEmpty) {
      buffer.writeln('\nPrevención:');
      for (final p in prevention) {
        buffer.writeln('• $p');
      }
    }
    buffer.writeln('\nCuándo acudir al veterinario: $whenToSeeVet');
    if (veterinarians.isNotEmpty) {
      buffer.writeln('\nVeterinarios sugeridos:');
      for (final v in veterinarians) {
        buffer.writeln('• ${v.name} (${v.specialty}) — ${v.location} — ${v.phone}');
      }
    }
    buffer.writeln('\n$_defaultDisclaimer');
    return buffer.toString().trim();
  }
}
