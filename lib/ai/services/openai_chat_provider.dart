import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smartfarm_ai/ai/config/ai_config.dart';
import 'package:smartfarm_ai/ai/services/cloud_ai_provider.dart';

/// Integración OpenAI Chat Completions (GPT-4o-mini recomendado).
class OpenAiChatProvider implements CloudAiProvider {
  OpenAiChatProvider({http.Client? client, String? apiKey, String? model})
      : _client = client ?? http.Client(),
        _model = model ?? AiConfig.openAiModel;

  final http.Client _client;
  final String _model;

  String get _apiKey => AiConfig.openAiApiKey;

  static final Uri _endpoint = Uri.parse('https://api.openai.com/v1/chat/completions');

  @override
  String get displayName => 'OpenAI GPT';

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  Future<Map<String, dynamic>> completeStructured({
    required List<Map<String, String>> messages,
  }) async {
    if (!isConfigured) throw Exception('OPENAI_API_KEY no configurada');

    final payload = {
      'model': _model,
      'temperature': 0.25,
      'max_tokens': 1200,
      'response_format': {'type': 'json_object'},
      'messages': messages,
    };

    final res = await _client.post(
      _endpoint,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode == 429) {
      throw Exception('Límite de OpenAI alcanzado. Intente más tarde.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final snippet = res.body.length > 180 ? '${res.body.substring(0, 180)}…' : res.body;
      throw Exception('OpenAI ${res.statusCode}: $snippet');
    }

    final decoded = jsonDecode(res.body) as Map<String, Object?>;
    final choices = (decoded['choices'] as List).cast<Map<String, Object?>>();
    final msg = (choices.first['message'] as Map).cast<String, Object?>();
    final content = (msg['content'] as String?)?.trim();
    if (content == null || content.isEmpty) throw Exception('Respuesta vacía de OpenAI');

    try {
      return jsonDecode(_extractJson(content)) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw Exception('OpenAI devolvió JSON inválido: $e');
    }
  }

  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return text;
    return text.substring(start, end + 1);
  }
}
