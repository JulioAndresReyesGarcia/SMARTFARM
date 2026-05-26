import 'package:smartfarm_ai/ai/config/ai_config.dart';
import 'package:smartfarm_ai/ai/services/backend_chat_provider.dart';
import 'package:smartfarm_ai/ai/services/cloud_ai_provider.dart';
import 'package:smartfarm_ai/ai/services/gemini_chat_provider.dart';
import 'package:smartfarm_ai/ai/services/openai_chat_provider.dart';

/// Factory que resuelve el proveedor de IA según configuración.
class CloudAiProviderFactory {
  CloudAiProviderFactory({
    OpenAiChatProvider? openAi,
    GeminiChatProvider? gemini,
    BackendChatProvider? backend,
  })  : _openAi = openAi ?? OpenAiChatProvider(),
        _gemini = gemini ?? GeminiChatProvider(),
        _backend = backend ?? BackendChatProvider();

  final OpenAiChatProvider _openAi;
  final GeminiChatProvider _gemini;
  final BackendChatProvider _backend;

  CloudAiProvider? resolve() {
    final choice = AiConfig.resolveProvider();
    final primary = _providerFor(choice);
    if (primary != null) return primary;

    if (_openAi.isConfigured) return _openAi;
    if (_gemini.isConfigured) return _gemini;
    if (_backend.isConfigured) return _backend;
    return null;
  }

  CloudAiProvider? _providerFor(AiCloudProvider choice) {
    switch (choice) {
      case AiCloudProvider.backend:
        return _backend.isConfigured ? _backend : null;
      case AiCloudProvider.gemini:
        return _gemini.isConfigured ? _gemini : null;
      case AiCloudProvider.openai:
        return _openAi.isConfigured ? _openAi : null;
      case AiCloudProvider.auto:
        return null;
    }
  }

  OpenAiChatProvider get openAi => _openAi;
  GeminiChatProvider get gemini => _gemini;
  BackendChatProvider get backend => _backend;
}
