import 'package:smartfarm_ai/ai/knowledge/livestock_knowledge.dart';
import 'package:smartfarm_ai/ai/models/chat_message.dart';
import 'package:smartfarm_ai/ai/models/risk_level.dart';
import 'package:smartfarm_ai/ai/models/user_intent.dart';
import 'package:smartfarm_ai/ai/services/conversation_manager.dart';
import 'package:smartfarm_ai/ai/services/symptom_analyzer.dart';
import 'package:smartfarm_ai/services/ai_service.dart';

/// Construye prompts profesionales para conversación ganadera (GPT / Gemini).
class PromptBuilder {
  const PromptBuilder({ConversationManager? conversationManager})
      : _conversation = conversationManager ?? const ConversationManager();

  final ConversationManager _conversation;

  static const systemPrompt = '''
Eres SmartFarm AI, veterinario-ganadero virtual especializado en salud animal, nutrición y producción.
Respondes SIEMPRE en español, de forma clara, empática y directa — como un asesor que conoce al productor.

REGLA #1 — RESPONDE A LO QUE PREGUNTARON:
- Lee la PREGUNTA DEL USUARIO con atención y responde EXACTAMENTE sobre ese tema.
- Si preguntan por fiebre, habla de fiebre. Si preguntan ración, habla de alimentación.
- NO des respuestas genéricas ni cambies de tema.
- Menciona en tu respuesta las palabras clave o síntomas que el usuario describió.

REGLA #2 — USA EL CONTEXTO DEL ANIMAL (OBLIGATORIO):
- La consulta es sobre UN animal específico: usa su NOMBRE y ESPECIE en la respuesta.
- Ejemplo: "Para Nube (Caprino, 45 kg)..." — NO hables de bovinos si el animal es caprino.
- Adapta consejos a la especie exacta registrada (caprino ≠ bovino ≠ aves).
- Si hay historial, mantén continuidad solo para ESE animal.

REGLA #3 — SEGURIDAD VETERINARIA:
- NUNCA des diagnósticos definitivos. Usa: "posible", "orientativo", "podría indicar".
- Emergencias (sangre, convulsiones, colapso, no respira): urgencia veterinaria INMEDIATA.
- No prescribas medicamentos con dosis específicas.
- Si la pregunta NO es sobre ganadería/salud animal, indícalo brevemente y ofrece ayuda ganadera.

FORMATO — responde ÚNICAMENTE con JSON válido:
{
  "summary": "respuesta directa a la pregunta (2-5 oraciones, menciona síntomas/tema del usuario)",
  "probableAssessment": "evaluación orientativa relacionada con la consulta",
  "detectedSymptoms": ["síntomas que el usuario mencionó"],
  "riskLevel": "bajo|medio|alto|emergencia",
  "recommendations": ["acción concreta 1", "acción concreta 2"],
  "prevention": ["medida preventiva"],
  "whenToSeeVet": "cuándo acudir al veterinario para ESTE caso"
}
''';

  List<Map<String, String>> buildMessages({
    required String question,
    required AiAnimalContext ctx,
    required UserIntent intent,
    SymptomAnalysis? symptomAnalysis,
    List<ChatMessage>? history,
    AiRecommendation? nutritionRec,
  }) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    final recent = _conversation.trimForApi(history);
    for (final m in recent) {
      messages.add({
        'role': m.role == 'user' ? 'user' : 'assistant',
        'content': m.content,
      });
    }

    final contextBlock = _buildContextBlock(
      ctx: ctx,
      intent: intent,
      symptomAnalysis: symptomAnalysis,
      nutritionRec: nutritionRec,
    );

    // Pregunta primero — la IA debe enfocarse en esto
    final userMessage = StringBuffer()
      ..writeln('PREGUNTA A RESPONDER (obligatorio responder esto):')
      ..writeln(question.trim())
      ..writeln()
      ..writeln(contextBlock);

    messages.add({
      'role': 'user',
      'content': userMessage.toString().trim(),
    });

    return messages;
  }

  String _buildContextBlock({
    required AiAnimalContext ctx,
    required UserIntent intent,
    SymptomAnalysis? symptomAnalysis,
    AiRecommendation? nutritionRec,
  }) {
    final buf = StringBuffer('CONTEXTO DEL ANIMAL REGISTRADO:\n');

    final name = ctx.nombre.trim().isNotEmpty ? ctx.nombre.trim() : 'Sin nombre';
    buf.writeln('- Nombre: $name');
    buf.writeln('- Especie: ${ctx.tipo}');
    buf.writeln('- Peso: ${ctx.pesoKg.toStringAsFixed(1)} kg');
    buf.writeln('- Edad: ${ctx.edadMeses} meses');
    buf.writeln('- Tema detectado: ${intent.label}');
    buf.writeln('- Perfil especie: ${LivestockKnowledge.speciesGuidance(ctx.tipo)}');

    if (ctx.productionHistory.isNotEmpty) {
      final avg = ctx.productionHistory.reduce((a, b) => a + b) / ctx.productionHistory.length;
      buf.writeln('- Promedio producción reciente: ${avg.toStringAsFixed(1)}');
    }
    if (ctx.feedingKgHistory.isNotEmpty) {
      final avg = ctx.feedingKgHistory.reduce((a, b) => a + b) / ctx.feedingKgHistory.length;
      buf.writeln('- Promedio ración reciente: ${avg.toStringAsFixed(2)} kg/día');
    }
    if (ctx.feedingTypeHistory.isNotEmpty) {
      buf.writeln('- Alimentos usados: ${ctx.feedingTypeHistory.take(3).join(", ")}');
    }

    if (symptomAnalysis != null) {
      if (symptomAnalysis.detectedSymptoms.isNotEmpty) {
        buf.writeln('- Síntomas detectados en la consulta: ${symptomAnalysis.detectedSymptoms.join(", ")}');
      }
      if (symptomAnalysis.matches.isNotEmpty) {
        final conditions = symptomAnalysis.matches.map((c) => c.name).join('; ');
        buf.writeln('- Posibles causas orientativas (pre-análisis): $conditions');
      }
      buf.writeln('- Nivel de riesgo pre-análisis: ${symptomAnalysis.riskLevel.label}');
    }

    if (nutritionRec != null && _intentNeedsNutrition(intent)) {
      buf.writeln(
        '- Ración sugerida por sistema: ${nutritionRec.suggestedFoodKgPerDay.toStringAsFixed(2)} kg/día de ${nutritionRec.feedType}',
      );
    }

    final knowledge = _knowledgeForIntent(intent, symptomAnalysis);
    if (knowledge.length > 1) {
      buf.writeln('\nREFERENCIA GANADERA (usa si aplica a la pregunta):');
      for (final k in knowledge.skip(1).take(4)) {
        buf.writeln('• $k');
      }
    }

    return buf.toString().trim();
  }

  bool _intentNeedsNutrition(UserIntent intent) =>
      intent == UserIntent.nutricion || intent == UserIntent.produccion;

  List<String> _knowledgeForIntent(UserIntent intent, SymptomAnalysis? analysis) {
    final snippets = <String>[LivestockKnowledge.disclaimer];

    if (analysis != null && analysis.matches.isNotEmpty) {
      for (final c in analysis.matches) {
        snippets.add('${c.name}: ${c.careAdvice} | Prevención: ${c.prevention} | Vet: ${c.vetWhen}');
      }
    }

    switch (intent) {
      case UserIntent.vacunacion:
        snippets.addAll(LivestockKnowledge.vaccinationTips);
      case UserIntent.higiene:
        snippets.add('Bioseguridad: limpieza, cuarentena, control de visitantes.');
      case UserIntent.clima:
        snippets.add('Calor: sombra y agua. Frío: refugio seco.');
      default:
        break;
    }
    return snippets;
  }

  static RiskLevel parseRisk(String? value) {
    switch (value?.toLowerCase()) {
      case 'emergencia':
        return RiskLevel.emergencia;
      case 'alto':
        return RiskLevel.alto;
      case 'medio':
        return RiskLevel.medio;
      default:
        return RiskLevel.bajo;
    }
  }

  static List<String> parseStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
  }
}
