import 'package:smartfarm_ai/ai/models/ai_assistant_response.dart';
import 'package:smartfarm_ai/ai/models/chat_message.dart';
import 'package:smartfarm_ai/ai/models/risk_level.dart';
import 'package:smartfarm_ai/ai/models/user_intent.dart';
import 'package:smartfarm_ai/ai/services/livestock_assistant_service.dart';
import 'package:smartfarm_ai/services/ai_service.dart';
import 'package:smartfarm_ai/services/analytics_service.dart';
import 'package:smartfarm_ai/services/animales_service.dart';

/// Fachada de chat IA — mantiene compatibilidad con código existente.
class AiChatService {
  AiChatService({
    LivestockAssistantService? assistant,
    AnimalesService? animales,
    AnalyticsService? analytics,
  })  : _assistant = assistant ?? LivestockAssistantService(),
        _animales = animales ?? AnimalesService(),
        _analytics = analytics ?? AnalyticsService();

  final LivestockAssistantService _assistant;
  final AnimalesService _animales;
  final AnalyticsService _analytics;

  /// Respuesta estructurada del asistente avanzado.
  Future<AiAssistantResponse> askStructured({
    required int animalId,
    required String question,
    List<ChatMessage>? history,
    UserIntent? forcedIntent,
  }) async {
    final ctx = await _loadContext(animalId);
    if (ctx == null) {
      return const AiAssistantResponse(
        intent: UserIntent.general,
        riskLevel: RiskLevel.bajo,
        summary: 'No se encontró el animal seleccionado.',
        whenToSeeVet: 'Verifica que el animal exista en tu registro.',
      );
    }
    return _assistant.ask(
      question: question,
      ctx: ctx,
      history: history,
      forcedIntent: forcedIntent,
    );
  }

  /// API legacy: devuelve texto plano (compatible con pantallas anteriores).
  Future<String> ask({
    required int animalId,
    required String question,
    List<ChatMessage>? history,
  }) async {
    try {
      final response = await askStructured(
        animalId: animalId,
        question: question,
        history: history,
      );
      return response.toDisplayText();
    } catch (e) {
      return 'Error al procesar la consulta: $e';
    }
  }

  Future<AiAnimalContext?> _loadContext(int animalId) async {
    final animal = await _animales.getById(animalId);
    if (animal == null) return null;

    final production = await _analytics.loadDoubles(
      table: 'registros_produccion',
      animalId: animalId,
      field: 'produccion',
      limit: 30,
    );
    final feedingKg = await _analytics.loadDoubles(
      table: 'raciones',
      animalId: animalId,
      field: 'cantidad',
      limit: 30,
    );
    final feedingTypes = await _analytics.loadStrings(
      table: 'raciones',
      animalId: animalId,
      field: 'tipo_alimento',
      limit: 30,
    );
    final costs = await _analytics.loadDoubles(
      table: 'costos_alimentacion',
      animalId: animalId,
      field: 'costo',
      limit: 30,
    );

    return AiAnimalContext(
      animalId: animalId,
      nombre: animal.nombre,
      tipo: animal.tipo,
      pesoKg: animal.peso,
      edadMeses: animal.edad,
      productionHistory: production,
      feedingKgHistory: feedingKg,
      feedingTypeHistory: feedingTypes,
      feedingCostsHistory: costs,
    );
  }
}

