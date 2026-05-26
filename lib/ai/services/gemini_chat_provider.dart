import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smartfarm_ai/ai/config/ai_config.dart';
import 'package:smartfarm_ai/ai/services/cloud_ai_provider.dart';

/// Integración Google Gemini (alternativa económica).
class GeminiChatProvider implements CloudAiProvider {
  GeminiChatProvider({http.Client? client, String? apiKey, String? model})
      : _client = client ?? http.Client(),
        _model = model ?? AiConfig.geminiModel;

  final http.Client _client;
  final String _model;

  String get _apiKey => AiConfig.geminiApiKey;

  @override
  String get displayName => 'Google Gemini';

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  Uri get _endpoint => Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
      );

  @override
  Future<Map<String, dynamic>> completeStructured({
    required List<Map<String, String>> messages,
  }) async {
    if (!isConfigured) throw Exception('GEMINI_API_KEY no configurada');

    // Gemini: system instruction + contents
    String? systemText;
    final contents = <Map<String, dynamic>>[];

    for (final m in messages) {
      if (m['role'] == 'system') {
        systemText = m['content'];
        continue;
      }
      contents.add({
        'role': m['role'] == 'assistant' ? 'model' : 'user',
        'parts': [{'text': m['content']}],
      });
    }

    final payload = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': 0.25,
        'maxOutputTokens': 1200,
        'responseMimeType': 'application/json',
      },
    };
    if (systemText != null) {
      payload['systemInstruction'] = {
        'parts': [{'text': systemText}],
      };
    }

    final res = await _client.post(
      _endpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode == 429) {
      throw Exception('Límite de Gemini alcanzado. Intente más tarde.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Gemini error ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) throw Exception('Gemini sin candidatos');

    final parts = (candidates.first as Map)['content']?['parts'] as List?;
    final text = parts?.isNotEmpty == true ? parts!.first['text'] as String? : null;
    if (text == null || text.trim().isEmpty) throw Exception('Respuesta vacía de Gemini');

    return jsonDecode(text.trim()) as Map<String, dynamic>;
  }
}
