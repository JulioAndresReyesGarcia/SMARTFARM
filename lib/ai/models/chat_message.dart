/// Mensaje de conversación para mantener contexto.
class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, String> toLegacyMap() => {'role': role, 'text': content};
}
