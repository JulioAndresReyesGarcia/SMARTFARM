import 'package:smartfarm_ai/ai/config/ai_config.dart';
import 'package:smartfarm_ai/ai/knowledge/livestock_knowledge.dart';
import 'package:smartfarm_ai/ai/models/ai_assistant_response.dart';
import 'package:smartfarm_ai/ai/models/chat_message.dart';
import 'package:smartfarm_ai/ai/models/risk_level.dart';
import 'package:smartfarm_ai/ai/models/user_intent.dart';
import 'package:smartfarm_ai/ai/models/veterinarian_suggestion.dart';
import 'package:smartfarm_ai/ai/services/ai_settings_store.dart';
import 'package:smartfarm_ai/ai/services/backend_chat_provider.dart';
import 'package:smartfarm_ai/ai/services/cloud_ai_provider.dart';
import 'package:smartfarm_ai/ai/services/cloud_ai_provider_factory.dart';
import 'package:smartfarm_ai/ai/services/conversation_manager.dart';
import 'package:smartfarm_ai/ai/services/intent_detector.dart';
import 'package:smartfarm_ai/ai/services/prompt_builder.dart';
import 'package:smartfarm_ai/ai/services/symptom_analyzer.dart';
import 'package:smartfarm_ai/ai/services/veterinarian_recommender.dart';
import 'package:smartfarm_ai/ai/utils/animal_context_formatter.dart';
import 'package:smartfarm_ai/ai/utils/text_normalize.dart';
import 'package:smartfarm_ai/services/ai_service.dart';

/// Orquestador del asistente ganadero con IA conversacional (OpenAI / Gemini / Backend).
class LivestockAssistantService {
  LivestockAssistantService({
    AiService? ai,
    IntentDetector? intentDetector,
    SymptomAnalyzer? symptomAnalyzer,
    VeterinarianRecommender? vetRecommender,
    PromptBuilder? promptBuilder,
    ConversationManager? conversationManager,
    CloudAiProviderFactory? providerFactory,
  })  : _ai = ai ?? AiService(),
        _intentDetector = intentDetector ?? const IntentDetector(),
        _symptomAnalyzer = symptomAnalyzer ?? const SymptomAnalyzer(),
        _vetRecommender = vetRecommender ?? const VeterinarianRecommender(),
        _promptBuilder = promptBuilder ?? const PromptBuilder(),
        _conversation = conversationManager ?? const ConversationManager(),
        _providers = providerFactory ?? CloudAiProviderFactory();

  final AiService _ai;
  final IntentDetector _intentDetector;
  final SymptomAnalyzer _symptomAnalyzer;
  final VeterinarianRecommender _vetRecommender;
  final PromptBuilder _promptBuilder;
  final ConversationManager _conversation;
  final CloudAiProviderFactory _providers;

  Future<AiAssistantResponse> ask({
    required String question,
    required AiAnimalContext ctx,
    List<ChatMessage>? history,
    UserIntent? forcedIntent,
  }) async {
    if (!AiSettingsStore.instance.isLoaded) {
      await AiSettingsStore.instance.load();
    }

    final filteredHistory = _filterHistoryForAnimal(history, ctx);
    final trimmedHistory = _conversation.trimForApi(filteredHistory);
    final cleanQuestion = question.trim();

    final intent = forcedIntent ?? _intentDetector.detect(cleanQuestion);
    final userContext = _userMessagesText(trimmedHistory);
    final symptomText = userContext.isEmpty ? cleanQuestion : '$userContext $cleanQuestion';

    final symptomAnalysis = _needsSymptomAnalysis(intent, cleanQuestion)
        ? _symptomAnalyzer.analyze(question: symptomText, species: ctx.tipo)
        : null;

    final nutritionRec = _intentNeedsNutrition(intent) ? await _ai.recommend(ctx) : null;

    AiAssistantResponse? response;
    String? cloudFallbackReason;

    if (AiConfig.hasCloudAi) {
      final cloudResult = await _tryCloud(
        question: cleanQuestion,
        ctx: ctx,
        intent: intent,
        symptomAnalysis: symptomAnalysis,
        history: trimmedHistory,
        nutritionRec: nutritionRec,
      );
      response = cloudResult.response;
      cloudFallbackReason = cloudResult.fallbackReason;
    }

    response ??= _buildLocalResponse(
      question: cleanQuestion,
      ctx: ctx,
      intent: intent,
      symptomAnalysis: symptomAnalysis,
      nutritionRec: nutritionRec,
      cloudFallbackReason: cloudFallbackReason,
    );

    response = _focusOnQuestion(response, cleanQuestion, intent);
    response = _bindToAnimal(response, ctx);
    return _enrichWithVets(response, ctx.tipo, response.intent, response.riskLevel);
  }

  String _userMessagesText(List<ChatMessage> history) {
    return history
        .where((m) => m.role == 'user')
        .map((m) => AnimalContextFormatter.stripHistoryTag(m.content))
        .join(' ')
        .trim();
  }

  /// Asegura que la respuesta mencione el tema de la pregunta.
  AiAssistantResponse _focusOnQuestion(
    AiAssistantResponse response,
    String question,
    UserIntent intent,
  ) {
    final q = normalizeForMatch(question);
    final summary = response.summary;
    final lower = normalizeForMatch(summary);

    final topicHints = _topicKeywords(intent, question);
    final mentionsTopic = topicHints.any((k) => lower.contains(normalizeForMatch(k)));
    if (mentionsTopic || topicHints.isEmpty) return response;

    final lead = _topicLead(intent, question);
    return AiAssistantResponse(
      intent: response.intent,
      riskLevel: response.riskLevel,
      summary: '$lead $summary',
      probableAssessment: response.probableAssessment,
      recommendations: response.recommendations,
      prevention: response.prevention,
      whenToSeeVet: response.whenToSeeVet,
      veterinarians: response.veterinarians,
      disclaimer: response.disclaimer,
      usedCloudAi: response.usedCloudAi,
      cloudProviderName: response.cloudProviderName,
      cloudFallbackReason: response.cloudFallbackReason,
      detectedSymptoms: response.detectedSymptoms,
    );
  }

  List<String> _topicKeywords(UserIntent intent, String question) {
    final q = normalizeForMatch(question);
    return switch (intent) {
      UserIntent.sintomas => ['fiebre', 'sintoma', 'dolor', 'diarrea', 'tos', 'come'],
      UserIntent.nutricion => ['racion', 'aliment', 'comida', 'kg', 'forraje'],
      UserIntent.produccion => ['produc', 'leche', 'huevo', 'rendimiento'],
      UserIntent.vacunacion => ['vacuna'],
      UserIntent.emergencia => ['emergencia', 'urgente', 'debil', 'colapso'],
      UserIntent.veterinario => ['veterinario'],
      _ => q.split(' ').where((w) => w.length > 4).take(3).toList(),
    };
  }

  String _topicLead(UserIntent intent, String question) {
    return switch (intent) {
      UserIntent.sintomas => 'Respecto a los síntomas que describe:',
      UserIntent.nutricion => 'Sobre la alimentación que consulta:',
      UserIntent.produccion => 'Sobre la producción que consulta:',
      UserIntent.vacunacion => 'Sobre vacunación:',
      UserIntent.emergencia => 'Ante esta emergencia:',
      UserIntent.veterinario => 'Para encontrar veterinario:',
      UserIntent.comportamiento => 'Sobre el comportamiento:',
      UserIntent.higiene => 'Sobre higiene y bioseguridad:',
      UserIntent.clima => 'Sobre condiciones climáticas:',
      _ => 'Respondiendo a su pregunta:',
    };
  }

  List<ChatMessage> _filterHistoryForAnimal(List<ChatMessage>? history, AiAnimalContext ctx) {
    if (history == null || history.isEmpty) return const [];
    return history
        .where(
          (m) => AnimalContextFormatter.historyMatchesAnimal(m.content, ctx.nombre, ctx.tipo),
        )
        .toList(growable: false);
  }

  AiAssistantResponse _bindToAnimal(AiAssistantResponse response, AiAnimalContext ctx) {
    final label = AnimalContextFormatter.fullLabel(
      nombre: ctx.nombre,
      tipo: ctx.tipo,
      pesoKg: ctx.pesoKg,
      edadMeses: ctx.edadMeses,
    );
    final summary = response.summary;
    final lower = summary.toLowerCase();
    final hasName = ctx.nombre.trim().isNotEmpty && lower.contains(ctx.nombre.toLowerCase());
    final hasSpecies = lower.contains(ctx.tipo.toLowerCase()) ||
        lower.contains(LivestockKnowledge.normalizeSpecies(ctx.tipo));

    if (hasName || hasSpecies) return response;

    return AiAssistantResponse(
      intent: response.intent,
      riskLevel: response.riskLevel,
      summary: 'Para $label: $summary',
      probableAssessment: response.probableAssessment,
      recommendations: response.recommendations,
      prevention: response.prevention,
      whenToSeeVet: response.whenToSeeVet,
      veterinarians: response.veterinarians,
      disclaimer: response.disclaimer,
      usedCloudAi: response.usedCloudAi,
      cloudProviderName: response.cloudProviderName,
      cloudFallbackReason: response.cloudFallbackReason,
      detectedSymptoms: response.detectedSymptoms,
    );
  }

  bool _isCareFollowUp(String question) {
    return textContainsAny(question, [
      'ayudar', 'puedo hacer', 'que hago', 'qué hago', 'que puedo', 'qué puedo',
      'recomiend', 'suger', 'cuidar', 'cuidado', 'hacer por', 'algo para',
    ]);
  }

  bool _intentNeedsNutrition(UserIntent intent) =>
      intent == UserIntent.nutricion || intent == UserIntent.produccion;

  bool _needsSymptomAnalysis(UserIntent intent, String question) {
    if (intent == UserIntent.sintomas ||
        intent == UserIntent.emergencia ||
        intent == UserIntent.comportamiento) {
      return true;
    }
    if (_isCareFollowUp(question)) return true;
    return _intentDetector.hasHealthKeywords(question);
  }

  Future<({AiAssistantResponse? response, String? fallbackReason})> _tryCloud({
    required String question,
    required AiAnimalContext ctx,
    required UserIntent intent,
    required SymptomAnalysis? symptomAnalysis,
    required List<ChatMessage> history,
    required AiRecommendation? nutritionRec,
  }) async {
    Object? lastError;

    for (final provider in _providerFallbackChain()) {
      try {
        final response = await _askWithProvider(
          provider,
          question: question,
          ctx: ctx,
          intent: intent,
          symptomAnalysis: symptomAnalysis,
          history: history,
          nutritionRec: nutritionRec,
        );
        return (response: response, fallbackReason: null);
      } catch (e) {
        lastError = e;
      }
    }

    return (response: null, fallbackReason: _friendlyCloudError(lastError));
  }

  List<CloudAiProvider> _providerFallbackChain() {
    final chain = <CloudAiProvider>[];
    void add(CloudAiProvider provider) {
      if (provider.isConfigured && !chain.contains(provider)) {
        chain.add(provider);
      }
    }

    final primary = _providers.resolve();
    if (primary != null) add(primary);
    add(_providers.openAi);
    add(_providers.gemini);
    add(_providers.backend);
    return chain;
  }

  Future<AiAssistantResponse> _askWithProvider(
    CloudAiProvider provider, {
    required String question,
    required AiAnimalContext ctx,
    required UserIntent intent,
    required SymptomAnalysis? symptomAnalysis,
    required List<ChatMessage> history,
    required AiRecommendation? nutritionRec,
  }) async {
    if (provider is BackendChatProvider) {
      final obj = await provider.chat(
        animalId: ctx.animalId,
        message: question,
        history: history,
      );
      return _parseBackendResponse(
        obj: obj,
        intent: intent,
        symptomAnalysis: symptomAnalysis,
        providerName: provider.displayName,
      );
    }

    final messages = _promptBuilder.buildMessages(
      question: question,
      ctx: ctx,
      intent: intent,
      symptomAnalysis: symptomAnalysis,
      history: history,
      nutritionRec: nutritionRec,
    );
    final obj = await provider.completeStructured(messages: messages);
    return _parseCloudResponse(
      obj: obj,
      intent: intent,
      symptomAnalysis: symptomAnalysis,
      providerName: provider.displayName,
    );
  }

  String? _friendlyCloudError(Object? error) {
    if (error == null) return null;
    final msg = error.toString();
    if (msg.contains('401')) {
      return 'Clave OpenAI inválida o expirada. Revise la API key en configuración (icono llave).';
    }
    if (msg.contains('429')) {
      return 'Límite de la API alcanzado. Intente más tarde.';
    }
    if (msg.contains('Sin proveedor')) {
      return 'No hay proveedor de IA disponible con la configuración actual.';
    }
    if (msg.contains('ClientException') ||
        msg.contains('SocketException') ||
        msg.contains('Failed host lookup')) {
      return 'Sin conexión a internet o servidor inaccesible.';
    }
    if (msg.length > 140) return '${msg.substring(0, 140)}…';
    return msg;
  }

  Future<AiAssistantResponse> _askCloud({
    required String question,
    required AiAnimalContext ctx,
    required UserIntent intent,
    required SymptomAnalysis? symptomAnalysis,
    required List<ChatMessage> history,
    required AiRecommendation? nutritionRec,
  }) async {
    final provider = _providers.resolve();
    if (provider == null) {
      throw Exception('Sin proveedor IA configurado');
    }
    return _askWithProvider(
      provider,
      question: question,
      ctx: ctx,
      intent: intent,
      symptomAnalysis: symptomAnalysis,
      history: history,
      nutritionRec: nutritionRec,
    );
  }

  AiAssistantResponse _parseBackendResponse({
    required Map<String, dynamic> obj,
    required UserIntent intent,
    required SymptomAnalysis? symptomAnalysis,
    required String providerName,
  }) {
    final parsedIntent = _parseIntentFromBackend(obj['intent'] as String?) ?? intent;
    final response = _parseCloudResponse(
      obj: obj,
      intent: parsedIntent,
      symptomAnalysis: symptomAnalysis,
      providerName: providerName,
    );
    final backendVets = _parseVeterinarians(obj['veterinarians']);
    if (backendVets.isEmpty) return response;

    return AiAssistantResponse(
      intent: response.intent,
      riskLevel: response.riskLevel,
      summary: response.summary,
      probableAssessment: response.probableAssessment,
      recommendations: response.recommendations,
      prevention: response.prevention,
      whenToSeeVet: response.whenToSeeVet,
      veterinarians: backendVets,
      disclaimer: (obj['disclaimer'] as String?) ?? response.disclaimer,
      usedCloudAi: obj['usedCloudAi'] == true || response.usedCloudAi,
      cloudProviderName: providerName,
      detectedSymptoms: response.detectedSymptoms,
      cloudFallbackReason: response.cloudFallbackReason,
    );
  }

  UserIntent? _parseIntentFromBackend(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final i in UserIntent.values) {
      if (i.name == name) return i;
    }
    return null;
  }

  List<VeterinarianSuggestion> _parseVeterinarians(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) {
          final name = e['name']?.toString() ?? '';
          if (name.isEmpty) return null;
          return VeterinarianSuggestion(
            name: name,
            specialty: e['specialty']?.toString() ?? '',
            location: e['location']?.toString() ?? '',
            phone: e['phone']?.toString() ?? '',
            isEmergency: e['isEmergency'] == true,
          );
        })
        .whereType<VeterinarianSuggestion>()
        .toList(growable: false);
  }

  AiAssistantResponse _parseCloudResponse({
    required Map<String, dynamic> obj,
    required UserIntent intent,
    required SymptomAnalysis? symptomAnalysis,
    required String providerName,
  }) {
    final risk = PromptBuilder.parseRisk(obj['riskLevel'] as String?);
    final effectiveRisk = symptomAnalysis != null && symptomAnalysis.riskLevel.index > risk.index
        ? symptomAnalysis.riskLevel
        : risk;

    final detected = PromptBuilder.parseStringList(obj['detectedSymptoms']);
    final mergedSymptoms = {
      ...detected,
      if (symptomAnalysis != null) ...symptomAnalysis.detectedSymptoms,
    }.toList();

    return AiAssistantResponse(
      intent: intent,
      riskLevel: effectiveRisk,
      summary: (obj['summary'] as String?)?.trim() ?? 'Consulta procesada.',
      probableAssessment: (obj['probableAssessment'] as String?)?.trim(),
      recommendations: PromptBuilder.parseStringList(obj['recommendations']),
      prevention: PromptBuilder.parseStringList(obj['prevention']),
      whenToSeeVet: (obj['whenToSeeVet'] as String?)?.trim() ?? _defaultVetAdvice(effectiveRisk),
      detectedSymptoms: mergedSymptoms,
      usedCloudAi: true,
      cloudProviderName: providerName,
    );
  }

  AiAssistantResponse _buildLocalResponse({
    required String question,
    required AiAnimalContext ctx,
    required UserIntent intent,
    required SymptomAnalysis? symptomAnalysis,
    required AiRecommendation? nutritionRec,
    String? cloudFallbackReason,
  }) {
    final risk = symptomAnalysis?.riskLevel ?? _riskFromIntent(intent);
    final animalLabel = AnimalContextFormatter.fullLabel(
      nombre: ctx.nombre,
      tipo: ctx.tipo,
      pesoKg: ctx.pesoKg,
      edadMeses: ctx.edadMeses,
    );
    final speciesGuide = LivestockKnowledge.speciesGuidance(ctx.tipo);

    final base = AiAssistantResponse(
      intent: intent,
      riskLevel: risk,
      summary: _localSummary(
        intent: intent,
        animalLabel: animalLabel,
        question: question,
        ctx: ctx,
        speciesGuide: speciesGuide,
        symptomAnalysis: symptomAnalysis,
        nutritionRec: nutritionRec,
      ),
      probableAssessment: _localAssessment(question, symptomAnalysis),
      recommendations: _localRecommendations(
        intent: intent,
        question: question,
        ctx: ctx,
        nutritionRec: nutritionRec,
        symptomAnalysis: symptomAnalysis,
      ),
      prevention: _localPrevention(intent, symptomAnalysis),
      whenToSeeVet: _localVetAdvice(risk, symptomAnalysis),
      detectedSymptoms: symptomAnalysis?.detectedSymptoms ?? const [],
      usedCloudAi: false,
      cloudFallbackReason: cloudFallbackReason,
    );
    return base;
  }

  String _localSummary({
    required UserIntent intent,
    required String animalLabel,
    required String question,
    required AiAnimalContext ctx,
    required String speciesGuide,
    required SymptomAnalysis? symptomAnalysis,
    required AiRecommendation? nutritionRec,
  }) {
    // Prioridad: intención explícita (chips o pregunta clara)
    if (intent == UserIntent.emergencia) {
      return 'Emergencia con $animalLabel: manténgala quieta, seco/a y llame al veterinario AHORA. '
          'No espere — signos de debilidad extrema requieren atención inmediata.';
    }

    if (intent == UserIntent.veterinario) {
      return 'Para $animalLabel (${ctx.tipo}): contacte un médico veterinario especializado en '
          '${ctx.tipo.toLowerCase()}. Lleve nota de síntomas, temperatura y tiempo de evolución.';
    }

    if (intent == UserIntent.nutricion && nutritionRec != null) {
      return 'Ración para $animalLabel: ${nutritionRec.suggestedFoodKgPerDay.toStringAsFixed(2)} kg/día '
          'de ${nutritionRec.feedType}. ${nutritionRec.expectedImpact} '
          '($speciesGuide)';
    }

    if (intent == UserIntent.vacunacion) {
      return 'Vacunas para $animalLabel (${ctx.tipo}): consulte calendario sanitario local. '
          'Registre fecha, lote y tipo. $speciesGuide';
    }

    if (intent == UserIntent.produccion) {
      return 'Producción de $animalLabel: revise ${LivestockKnowledge.productionLabel(ctx.tipo)}, '
          'alimentación, estrés y salud. $speciesGuide';
    }

    if (intent == UserIntent.sintomas || symptomAnalysis != null) {
      if (symptomAnalysis != null && symptomAnalysis.riskLevel == RiskLevel.emergencia) {
        return 'Para $animalLabel: posible emergencia. Contacte al veterinario de inmediato.';
      }
      if (symptomAnalysis != null && symptomAnalysis.matches.isNotEmpty) {
        final top = symptomAnalysis.matches.first;
        return 'Síntomas en $animalLabel: podría relacionarse con ${top.name.toLowerCase()}. '
            '${top.careAdvice} ($speciesGuide)';
      }
      if (_isCareFollowUp(question)) {
        return 'Para ayudar a $animalLabel: agua fresca, refugio seco, observe apetito y heces cada 6–8 h. '
            '$speciesGuide';
      }
      return 'Síntomas en $animalLabel: registre temperatura, apetito y heces. '
          '$speciesGuide Consulte veterinario si empeora en 24 h.';
    }

    if (intent == UserIntent.nutricion) {
      return 'Alimentación de $animalLabel: indique qué forraje/concentrado usa para calcular ración exacta. '
          '$speciesGuide';
    }

    return 'Sobre $animalLabel (${ctx.tipo}): $speciesGuide Cuénteme más detalles de su consulta.';
  }

  AiAssistantResponse _enrichWithVets(
    AiAssistantResponse response,
    String species,
    UserIntent intent,
    RiskLevel risk,
  ) {
    if (response.veterinarians.isNotEmpty) return response;
    final vets = _vetRecommender.recommend(species: species, intent: intent, risk: risk);
    if (vets.isEmpty) return response;
    return AiAssistantResponse(
      intent: response.intent,
      riskLevel: response.riskLevel,
      summary: response.summary,
      probableAssessment: response.probableAssessment,
      recommendations: response.recommendations,
      prevention: response.prevention,
      whenToSeeVet: response.whenToSeeVet,
      veterinarians: vets,
      disclaimer: response.disclaimer,
      usedCloudAi: response.usedCloudAi,
      cloudProviderName: response.cloudProviderName,
      cloudFallbackReason: response.cloudFallbackReason,
      detectedSymptoms: response.detectedSymptoms,
    );
  }

  String? _localAssessment(String question, SymptomAnalysis? analysis) {
    if (analysis == null || analysis.matches.isEmpty) {
      if (_intentDetector.hasHealthKeywords(question)) {
        return 'Los signos descritos requieren observación. Anote temperatura, apetito y heces cada 6–8 h.';
      }
      return null;
    }
    final names = analysis.matches.map((c) => c.name).join('; ');
    return 'Posibles causas orientativas para "$question": $names. Requiere confirmación veterinaria.';
  }

  List<String> _localRecommendations({
    required UserIntent intent,
    required String question,
    required AiAnimalContext ctx,
    required AiRecommendation? nutritionRec,
    required SymptomAnalysis? symptomAnalysis,
  }) {
    final recs = <String>[];

    if (symptomAnalysis != null) {
      for (final c in symptomAnalysis.matches.take(2)) {
        recs.add(c.careAdvice);
      }
      if (symptomAnalysis.detectedSymptoms.isNotEmpty) {
        recs.add('Monitoree: ${symptomAnalysis.detectedSymptoms.join(", ")} en las próximas 24 h.');
      }
      recs.add('Registre temperatura, apetito y heces.');
      recs.add(LivestockKnowledge.speciesGuidance(ctx.tipo));
    }

    switch (intent) {
      case UserIntent.emergencia:
        recs.add('Llame urgencias veterinarias ahora.');
        recs.add('Mantenga al animal quieto y en lugar seguro.');
      case UserIntent.veterinario:
        recs.add('Contacte clínica veterinaria de ${ctx.tipo.toLowerCase()}.');
        recs.add('Anote síntomas, hora de inicio y temperatura si puede medirla.');
      case UserIntent.vacunacion:
        recs.add('Revise calendario de vacunas específico para ${ctx.tipo.toLowerCase()}.');
        recs.add('Registre lote, fecha y vía de aplicación.');
      case UserIntent.nutricion:
        if (nutritionRec != null) {
          recs.add('Ración: ${nutritionRec.suggestedFoodKgPerDay.toStringAsFixed(2)} kg/día · ${nutritionRec.feedType}.');
        }
        recs.add(LivestockKnowledge.speciesGuidance(ctx.tipo));
      case UserIntent.produccion:
        if (ctx.productionHistory.isNotEmpty) {
          recs.add('Promedio producción: ${_avg(ctx.productionHistory).toStringAsFixed(1)}.');
        }
        recs.add('Revise estrés, alimentación y salud como factores clave.');
      default:
        break;
    }

    if (recs.isEmpty) {
      if (_isCareFollowUp(question)) {
        recs.add('Agua limpia y fresca disponible todo el tiempo.');
        recs.add('Área seca, ventilada y sin corrientes de aire frío.');
        recs.add('Observe apetito, heces y temperatura cada 6–8 h.');
      } else {
        recs.add('Describa más detalles (síntomas, desde cuándo, alimentación) para orientarle mejor.');
      }
    }
    return recs;
  }

  List<String> _localPrevention(UserIntent intent, SymptomAnalysis? analysis) {
    final prev = <String>[];
    if (analysis != null) {
      for (final c in analysis.matches.take(2)) {
        prev.add(c.prevention);
      }
    }
    if (prev.isEmpty) {
      prev.add(switch (intent) {
        UserIntent.vacunacion => 'Calendario de vacunas actualizado.',
        UserIntent.higiene => 'Limpieza e instalaciones y bioseguridad.',
        UserIntent.nutricion => 'Transiciones graduales de dieta y agua limpia.',
        _ => 'Revisiones periódicas y registro diario.',
      });
    }
    return prev.toSet().toList();
  }

  String _localVetAdvice(RiskLevel risk, SymptomAnalysis? analysis) {
    if (analysis != null && analysis.matches.isNotEmpty) {
      return analysis.matches.first.vetWhen;
    }
    return _defaultVetAdvice(risk);
  }

  RiskLevel _riskFromIntent(UserIntent intent) => switch (intent) {
        UserIntent.emergencia => RiskLevel.emergencia,
        UserIntent.sintomas => RiskLevel.medio,
        _ => RiskLevel.bajo,
      };

  String _defaultVetAdvice(RiskLevel risk) => switch (risk) {
        RiskLevel.emergencia => 'Atención veterinaria inmediata.',
        RiskLevel.alto => 'Visita veterinaria en las próximas horas.',
        RiskLevel.medio => 'Consulta si persiste más de 24–48 h.',
        RiskLevel.bajo => 'Control rutinario.',
      };

  double _avg(List<double> xs) {
    if (xs.isEmpty) return 0;
    return xs.reduce((a, b) => a + b) / xs.length;
  }
}
