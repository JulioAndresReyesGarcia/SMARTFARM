import 'package:smartfarm_ai/ai/models/chat_message.dart';

/// Gestiona memoria temporal de conversación (optimiza tokens y mantiene contexto).
class ConversationManager {
  const ConversationManager({this.maxMessages = 12});

  final int maxMessages;

  /// Conserva los últimos N mensajes alternando user/assistant.
  List<ChatMessage> trimForApi(List<ChatMessage>? history) {
    if (history == null || history.isEmpty) return const [];
    if (history.length <= maxMessages) return List.unmodifiable(history);
    return List.unmodifiable(history.sublist(history.length - maxMessages));
  }

  /// Texto resumido del historial para prompts locales.
  String buildContextSummary(List<ChatMessage>? history) {
    final trimmed = trimForApi(history);
    if (trimmed.isEmpty) return '';
    return trimmed
        .map((m) => '${m.role == 'user' ? 'Usuario' : 'Asistente'}: ${m.content}')
        .join('\n');
  }
}
