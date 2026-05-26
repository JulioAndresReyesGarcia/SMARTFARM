import 'package:smartfarm_ai/ai/models/chat_message.dart';
import 'package:smartfarm_ai/core/config/app_config.dart';
import 'package:smartfarm_ai/core/network/api_client.dart';
import 'package:smartfarm_ai/ai/services/cloud_ai_provider.dart';

/// Chat IA vía backend (claves en servidor, nunca en el cliente).
class BackendChatProvider implements CloudAiProvider {
  BackendChatProvider([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  @override
  String get displayName => 'SmartFarm API';

  @override
  bool get isConfigured => AppConfig.useRemoteBackend;

  Future<Map<String, dynamic>> chat({
    required int animalId,
    required String message,
    List<ChatMessage>? history,
  }) async {
    final data = await _client.postJson('/api/ia/chat', {
      'animalId': animalId,
      'message': message,
      if (history != null && history.isNotEmpty)
        'history': history
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(growable: false),
    });
    return data;
  }

  @override
  Future<Map<String, dynamic>> completeStructured({
    required List<Map<String, String>> messages,
  }) async {
    throw UnsupportedError('Use chat() con animalId para el backend');
  }
}
