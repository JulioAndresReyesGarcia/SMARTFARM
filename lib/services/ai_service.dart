import 'dart:convert';

import 'package:http/http.dart' as http;

class AiRecommendation {
  final double suggestedFoodKgPerDay;
  final String feedType;
  final String expectedImpact;
  final String summary;

  const AiRecommendation({
    required this.suggestedFoodKgPerDay,
    required this.feedType,
    required this.expectedImpact,
    required this.summary,
  });

  String toStorageText() {
    final kg = suggestedFoodKgPerDay;
    final kgText = kg.isFinite ? kg.toStringAsFixed(2) : '0.00';
    return 'Cantidad sugerida: $kgText kg/día\n'
        'Tipo de alimento: $feedType\n'
        'Impacto esperado: $expectedImpact\n'
        '$summary';
  }
}

class AiAnimalContext {
  final int animalId;
  final String tipo;
  final double pesoKg;
  final int edadMeses;
  final List<double> productionHistory;
  final List<double> feedingKgHistory;
  final List<String> feedingTypeHistory;
  final List<double> feedingCostsHistory;

  const AiAnimalContext({
    required this.animalId,
    required this.tipo,
    required this.pesoKg,
    required this.edadMeses,
    required this.productionHistory,
    required this.feedingKgHistory,
    required this.feedingTypeHistory,
    required this.feedingCostsHistory,
  });
}

class AiService {
  final String openAiApiKey;
  final Uri openAiEndpoint;
  final http.Client _client;

  AiService({
    String? openAiApiKey,
    Uri? openAiEndpoint,
    http.Client? client,
  })  : openAiEndpoint = openAiEndpoint ?? Uri.parse('https://api.openai.com/v1/chat/completions'),
        openAiApiKey = (openAiApiKey ?? const String.fromEnvironment('OPENAI_API_KEY')).trim(),
        _client = client ?? http.Client();

  Future<AiRecommendation> recommend(AiAnimalContext ctx) async {
    final key = openAiApiKey;
    if (key.isNotEmpty) {
      try {
        final rec = await _recommendViaOpenAi(ctx, key);
        return rec;
      } catch (_) {
        return _recommendLocal(ctx);
      }
    }
    return _recommendLocal(ctx);
  }

  Future<AiRecommendation> _recommendViaOpenAi(AiAnimalContext ctx, String apiKey) async {
    final payload = {
      'model': 'gpt-4o-mini',
      'temperature': 0.2,
      'messages': [
        {
          'role': 'system',
          'content':
              'Eres un especialista en nutrición animal. Debes devolver únicamente un JSON válido con la recomendación.',
        },
        {
          'role': 'user',
          'content': jsonEncode({
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
            'output_schema': {
              'suggestedFoodKgPerDay': 'number',
              'feedType': 'string',
              'expectedImpact': 'string',
              'summary': 'string',
            },
            'constraints': [
              'La cantidad sugerida debe ser un número razonable según peso y edad',
              'El texto debe ser conciso y accionable',
              'No incluyas texto fuera del JSON',
            ],
          }),
        },
      ],
    };

    final res = await _client.post(
      openAiEndpoint,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('AI API error ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body) as Map<String, Object?>;
    final choices = (decoded['choices'] as List).cast<Map<String, Object?>>();
    final msg = (choices.first['message'] as Map).cast<String, Object?>();
    final content = (msg['content'] as String).trim();

    final jsonText = _extractJsonObject(content);
    final obj = (jsonDecode(jsonText) as Map).cast<String, Object?>();

    final suggested = (obj['suggestedFoodKgPerDay'] as num?)?.toDouble() ?? 0;
    final feedType = (obj['feedType'] as String?)?.trim();
    final expectedImpact = (obj['expectedImpact'] as String?)?.trim();
    final summary = (obj['summary'] as String?)?.trim();

    if (feedType == null || feedType.isEmpty || expectedImpact == null || expectedImpact.isEmpty || summary == null) {
      throw Exception('Invalid AI payload');
    }

    return AiRecommendation(
      suggestedFoodKgPerDay: suggested.isFinite ? suggested : 0,
      feedType: feedType,
      expectedImpact: expectedImpact,
      summary: summary,
    );
  }

  AiRecommendation _recommendLocal(AiAnimalContext ctx) {
    final peso = ctx.pesoKg;
    final edad = ctx.edadMeses;
    final prodAvg = _avg(ctx.productionHistory);
    final feedAvg = _avg(ctx.feedingKgHistory);
    final costAvg = _avg(ctx.feedingCostsHistory);

    final baseKg = (peso * 0.025).clamp(0.8, 18.0);
    final growthAdj = edad < 18 ? 1.08 : (edad > 48 ? 0.95 : 1.0);
    final underfedAdj = feedAvg > 0 && feedAvg < baseKg ? 1.06 : 1.0;
    final highCostAdj = costAvg > 0 ? (costAvg > 50 ? 0.97 : 1.0) : 1.0;
    final prodAdj = prodAvg > 0 ? (prodAvg < 8 ? 1.05 : 1.0) : 1.0;

    final suggested = (baseKg * growthAdj * underfedAdj * highCostAdj * prodAdj).clamp(0.8, 22.0);

    final dominantType = _dominant(ctx.feedingTypeHistory);
    final feedType = _pickFeedType(tipo: ctx.tipo, pesoKg: peso, prodAvg: prodAvg, dominantHistory: dominantType);

    final expectedImpact = _expectedImpact(prodAvg: prodAvg, costAvg: costAvg);
    final summary = _summary(
      pesoKg: peso,
      edadMeses: edad,
      prodAvg: prodAvg,
      feedAvg: feedAvg,
      costAvg: costAvg,
      feedType: feedType,
    );

    return AiRecommendation(
      suggestedFoodKgPerDay: double.parse(suggested.toStringAsFixed(2)),
      feedType: feedType,
      expectedImpact: expectedImpact,
      summary: summary,
    );
  }

  String _pickFeedType({
    required String tipo,
    required double pesoKg,
    required double prodAvg,
    required String? dominantHistory,
  }) {
    if (dominantHistory != null && dominantHistory.trim().isNotEmpty) return dominantHistory.trim();
    final t = tipo.toLowerCase();
    if (t.contains('capr')) return prodAvg > 4 ? 'Forraje + concentrado (proteína moderada)' : 'Forraje de calidad';
    if (t.contains('bov')) {
      if (pesoKg > 420 || prodAvg > 10) return 'Forraje + concentrado (alto en proteína)';
      if (pesoKg < 300) return 'Concentrado energético + forraje';
      return 'Forraje + concentrado balanceado';
    }
    return 'Ración balanceada';
  }

  String _expectedImpact({required double prodAvg, required double costAvg}) {
    if (prodAvg <= 0 && costAvg <= 0) return 'Mejora de consistencia y control de costos';
    if (prodAvg > 0 && prodAvg < 8) return 'Mejora de producción estimada 3–8% con seguimiento';
    if (costAvg > 0 && costAvg > 50) return 'Reducción de costo estimada 2–5% optimizando ración';
    return 'Mejora incremental con mejor eficiencia alimenticia';
  }

  String _summary({
    required double pesoKg,
    required int edadMeses,
    required double prodAvg,
    required double feedAvg,
    required double costAvg,
    required String feedType,
  }) {
    final parts = <String>[];
    parts.add('Base por peso/edad y registros recientes.');
    if (prodAvg > 0) parts.add('Prom. producción: ${prodAvg.toStringAsFixed(1)}.');
    if (feedAvg > 0) parts.add('Prom. alimentación: ${feedAvg.toStringAsFixed(1)} kg.');
    if (costAvg > 0) parts.add('Prom. costo: ${costAvg.toStringAsFixed(1)}.');
    parts.add('Revisar cada 7 días y ajustar según producción y condición corporal.');
    return 'Tipo sugerido: $feedType. ${parts.join(' ')}';
  }

  double _avg(List<double> xs) {
    if (xs.isEmpty) return 0;
    final sum = xs.fold<double>(0, (a, b) => a + b);
    return sum / xs.length;
  }

  String? _dominant(List<String> xs) {
    if (xs.isEmpty) return null;
    final counts = <String, int>{};
    for (final x in xs) {
      final k = x.trim();
      if (k.isEmpty) continue;
      counts[k] = (counts[k] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String _extractJsonObject(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) throw Exception('No JSON found');
    return text.substring(start, end + 1);
  }
}

