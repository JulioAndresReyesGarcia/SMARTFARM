import 'package:smartfarm_ai/ai/services/ai_settings_store.dart';
import 'package:smartfarm_ai/core/config/app_config.dart';

/// Proveedor de IA en la nube soportado por SmartFarm.
enum AiCloudProvider {
  openai,
  gemini,
  backend,
  auto,
}

/// Configuración central de IA conversacional.
/// Claves: app (SharedPreferences) → --dart-define → backend remoto.
class AiConfig {
  AiConfig._();

  static const String _providerEnv = String.fromEnvironment(
    'AI_PROVIDER',
    defaultValue: '',
  );

  static const String _openAiEnv = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  static const String _geminiEnv = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String openAiModel = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-4o-mini',
  );

  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-1.5-flash',
  );

  static String get openAiApiKey {
    final stored = AiSettingsStore.instance.openAiKey;
    if (stored.isNotEmpty) return stored;
    return _openAiEnv.trim();
  }

  static String get geminiApiKey {
    final stored = AiSettingsStore.instance.geminiKey;
    if (stored.isNotEmpty) return stored;
    return _geminiEnv.trim();
  }

  static String get _providerRaw {
    final stored = AiSettingsStore.instance.provider;
    if (stored.isNotEmpty && stored != 'auto') return stored;
    if (_providerEnv.trim().isNotEmpty) return _providerEnv.trim();
    return 'auto';
  }

  static AiCloudProvider get preferredProvider {
    switch (_providerRaw.toLowerCase()) {
      case 'openai':
        return AiCloudProvider.openai;
      case 'gemini':
        return AiCloudProvider.gemini;
      case 'backend':
        return AiCloudProvider.backend;
      default:
        return AiCloudProvider.auto;
    }
  }

  static bool get hasOpenAiKey => openAiApiKey.isNotEmpty;
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
  static bool get preferBackend => AppConfig.useRemoteBackend;

  static AiCloudProvider resolveProvider() {
    final pref = preferredProvider;

    if (pref == AiCloudProvider.openai && hasOpenAiKey) {
      return AiCloudProvider.openai;
    }
    if (pref == AiCloudProvider.gemini && hasGeminiKey) {
      return AiCloudProvider.gemini;
    }

    // Clave guardada en el dispositivo tiene prioridad sobre backend remoto
    // (evita modo local cuando el backend no responde pero OpenAI sí está configurado).
    if (pref == AiCloudProvider.auto || pref == AiCloudProvider.backend) {
      if (hasOpenAiKey) return AiCloudProvider.openai;
      if (hasGeminiKey) return AiCloudProvider.gemini;
    }

    if (pref == AiCloudProvider.backend || preferBackend) {
      return AiCloudProvider.backend;
    }

    return AiCloudProvider.openai;
  }

  static bool get hasCloudAi => hasOpenAiKey || hasGeminiKey || preferBackend;
}
