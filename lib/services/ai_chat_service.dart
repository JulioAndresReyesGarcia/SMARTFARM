import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:smartfarm_ai/database/app_database.dart';
import 'package:smartfarm_ai/models/animal.dart';
import 'package:smartfarm_ai/services/ai_service.dart';

class AiChatService {
  final AiService _ai;
  final http.Client _client;

  AiChatService({AiService? ai, http.Client? client})
      : _ai = ai ?? AiService(),
        _client = client ?? http.Client();

  Future<String> ask({required int animalId, required String question}) async {
    final db = await AppDatabase.instance.database;
    final animalRows = await db.query('animales', where: 'id = ?', whereArgs: [animalId], limit: 1);
    if (animalRows.isEmpty) return 'No se encontró el animal.';
    final animal = Animal.fromMap(animalRows.first);

    final production = await _loadDoubles(db, table: 'registros_produccion', animalId: animalId, field: 'produccion', limit: 30);
    final feedingKg = await _loadDoubles(db, table: 'raciones', animalId: animalId, field: 'cantidad', limit: 30);
    final feedingTypes = await _loadStrings(db, table: 'raciones', animalId: animalId, field: 'tipo_alimento', limit: 30);
    final costs = await _loadDoubles(db, table: 'costos_alimentacion', animalId: animalId, field: 'costo', limit: 30);

    final ctx = AiAnimalContext(
      animalId: animalId,
      tipo: animal.tipo,
      pesoKg: animal.peso,
      edadMeses: animal.edad,
      productionHistory: production,
      feedingKgHistory: feedingKg,
      feedingTypeHistory: feedingTypes,
      feedingCostsHistory: costs,
    );

    final key = _ai.openAiApiKey;
    if (key.isNotEmpty) {
      try {
        return await _askViaOpenAi(question: question, ctx: ctx, apiKey: key, endpoint: _ai.openAiEndpoint);
      } catch (_) {
        final rec = await _ai.recommend(ctx);
        return _localAnswer(question: question, ctx: ctx, rec: rec);
      }
    }

    final rec = await _ai.recommend(ctx);
    return _localAnswer(question: question, ctx: ctx, rec: rec);
  }

  String _localAnswer({
    required String question,
    required AiAnimalContext ctx,
    required AiRecommendation rec,
  }) {
    final q = question.trim();
    final ql = q.toLowerCase();

    final prodAvg = _avg(ctx.productionHistory);
    final feedAvg = _avg(ctx.feedingKgHistory);
    final costAvg = _avg(ctx.feedingCostsHistory);

    final base = <String>[];
    base.add('Animal: ${ctx.tipo} · ${ctx.pesoKg.toStringAsFixed(0)} kg · ${ctx.edadMeses} meses.');
    if (prodAvg > 0) base.add('Prom. producción: ${prodAvg.toStringAsFixed(1)}.');
    if (feedAvg > 0) base.add('Prom. ración: ${feedAvg.toStringAsFixed(1)} kg/día.');
    if (costAvg > 0) base.add('Prom. costo: ${costAvg.toStringAsFixed(1)}.');

    if (_matchesAny(ql, const ['enfer', 'fiebr', 'diarr', 'tos', 'cojera', 'herida', 'apatico', 'no come', 'decaid', 'vomit'])) {
      final steps = <String>[
        'No puedo diagnosticar; si hay fiebre, sangre en heces, dificultad respiratoria o no come, contacta a un veterinario hoy.',
        'Aísla al animal y verifica signos: temperatura, hidratación, apetito, consistencia de heces, mucosas.',
        'Mantén agua limpia y sombra; evita cambios bruscos de ración.',
        'Si hubo cambio reciente de alimento, vuelve 24–48 h a una ración más estable y reintroduce gradualmente.',
      ];

      final nutrition = <String>[];
      nutrition.add('Mientras se estabiliza, prioriza forraje de buena calidad y controla la cantidad.');
      nutrition.add('Cantidad objetivo (si come normal): ${rec.suggestedFoodKgPerDay.toStringAsFixed(2)} kg/día · Tipo: ${rec.feedType}.');

      return [
        ...base,
        '',
        'Sobre tu consulta: "$q"',
        '',
        'Acciones inmediatas',
        for (final s in steps) '- $s',
        '',
        'Nutrición recomendada (orientativa)',
        for (final n in nutrition) '- $n',
      ].join('\n');
    }

    if (_matchesAny(ql, const ['costo', 'barato', 'gasto', 'reduc', 'ahorr', 'caro'])) {
      final tips = <String>[
        'Usa el tipo de alimento dominante del historial y evita rotar marcas/tipos sin transición.',
        'Optimiza la ración hacia eficiencia: ajusta 3–5% y monitorea producción 7 días.',
        'Si el costo promedio es alto, prioriza forraje de calidad y reduce concentrado sin comprometer producción.',
      ];
      return [
        ...base,
        '',
        'Objetivo: reducir costo sin perder producción.',
        '',
        'Recomendación base',
        '- Cantidad sugerida: ${rec.suggestedFoodKgPerDay.toStringAsFixed(2)} kg/día',
        '- Tipo: ${rec.feedType}',
        '- Impacto esperado: ${rec.expectedImpact}',
        '',
        'Ajustes sugeridos',
        for (final t in tips) '- $t',
      ].join('\n');
    }

    if (_matchesAny(ql, const ['produc', 'leche', 'mejor', 'subir', 'aument'])) {
      final tips = <String>[
        'Revisa consistencia diaria: misma hora, misma calidad de agua y forraje.',
        'Si la producción promedio es baja, sube la ración 3–6% por 5–7 días y evalúa respuesta.',
        'Evita aumentos bruscos; transiciona en 3–5 días.',
      ];
      return [
        ...base,
        '',
        'Objetivo: mejorar producción.',
        '',
        'Recomendación base',
        '- Cantidad sugerida: ${rec.suggestedFoodKgPerDay.toStringAsFixed(2)} kg/día',
        '- Tipo: ${rec.feedType}',
        '- Impacto esperado: ${rec.expectedImpact}',
        '',
        'Siguiente paso',
        for (final t in tips) '- $t',
      ].join('\n');
    }

    if (_matchesAny(ql, const ['cuanto', 'cantidad', 'racion', 'alimento', 'comida', 'kg', 'dieta', 'tipo'])) {
      return [
        ...base,
        '',
        'Recomendación',
        '- Cantidad sugerida: ${rec.suggestedFoodKgPerDay.toStringAsFixed(2)} kg/día',
        '- Tipo de alimento: ${rec.feedType}',
        '- Impacto esperado: ${rec.expectedImpact}',
        '',
        rec.summary,
      ].join('\n');
    }

    return [
      ...base,
      '',
      'Sobre tu consulta: "$q"',
      '',
      'Recomendación base',
      '- Cantidad sugerida: ${rec.suggestedFoodKgPerDay.toStringAsFixed(2)} kg/día',
      '- Tipo: ${rec.feedType}',
      '- Impacto esperado: ${rec.expectedImpact}',
      '',
      'Si me dices el síntoma principal (apetito, heces, fiebre, tos) o el objetivo (reducir costos, subir producción), te ajusto la recomendación.',
    ].join('\n');
  }

  bool _matchesAny(String ql, List<String> keys) {
    for (final k in keys) {
      if (ql.contains(k)) return true;
    }
    return false;
  }

  double _avg(List<double> xs) {
    if (xs.isEmpty) return 0;
    var sum = 0.0;
    for (final x in xs) {
      sum += x;
    }
    return sum / xs.length;
  }

  Future<String> _askViaOpenAi({
    required String question,
    required AiAnimalContext ctx,
    required String apiKey,
    required Uri endpoint,
  }) async {
    final payload = {
      'model': 'gpt-4o-mini',
      'temperature': 0.3,
      'messages': [
        {
          'role': 'system',
          'content':
              'Eres un asesor de nutrición animal. Responde en español, de forma breve, con pasos accionables y números cuando sea posible.',
        },
        {
          'role': 'user',
          'content': jsonEncode({
            'question': question,
            'animal': {
              'id': ctx.animalId,
              'tipo': ctx.tipo,
              'pesoKg': ctx.pesoKg,
              'edadMeses': ctx.edadMeses,
            },
            'productionHistory': ctx.productionHistory,
            'feedingHistoryKg': ctx.feedingKgHistory,
            'feedingTypes': ctx.feedingTypeHistory,
            'costHistory': ctx.feedingCostsHistory,
          }),
        },
      ],
    };

    final res = await _client.post(
      endpoint,
      headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('AI API error ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body) as Map<String, Object?>;
    final choices = (decoded['choices'] as List).cast<Map<String, Object?>>();
    final msg = (choices.first['message'] as Map).cast<String, Object?>();
    final content = (msg['content'] as String?)?.trim();
    if (content == null || content.isEmpty) throw Exception('Empty response');
    return content;
  }

  Future<List<double>> _loadDoubles(
    Database db, {
    required String table,
    required int animalId,
    required String field,
    required int limit,
  }) async {
    final rows = await db.query(
      table,
      columns: [field],
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'fecha DESC, id DESC',
      limit: limit,
    );
    return rows.map((r) => (r[field] as num).toDouble()).toList(growable: false);
  }

  Future<List<String>> _loadStrings(
    Database db, {
    required String table,
    required int animalId,
    required String field,
    required int limit,
  }) async {
    final rows = await db.query(
      table,
      columns: [field],
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'fecha DESC, id DESC',
      limit: limit,
    );
    return rows.map((r) => (r[field] as String?) ?? '').toList(growable: false);
  }
}

