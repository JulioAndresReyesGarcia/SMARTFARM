import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local de claves IA (configurables desde la app, sin recompilar).
class AiSettingsStore {
  AiSettingsStore._();
  static final AiSettingsStore instance = AiSettingsStore._();

  static const _openAiKey = 'ai_openai_api_key';
  static const _geminiKey = 'ai_gemini_api_key';
  static const _providerKey = 'ai_provider';

  String _openAi = '';
  String _gemini = '';
  String _provider = 'auto';
  bool _loaded = false;

  String get openAiKey => _openAi;
  String get geminiKey => _gemini;
  String get provider => _provider;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _openAi = prefs.getString(_openAiKey)?.trim() ?? '';
    _gemini = prefs.getString(_geminiKey)?.trim() ?? '';
    _provider = prefs.getString(_providerKey)?.trim() ?? 'auto';
    _loaded = true;
  }

  Future<void> saveOpenAiKey(String key) async {
    _openAi = key.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_openAi.isEmpty) {
      await prefs.remove(_openAiKey);
    } else {
      await prefs.setString(_openAiKey, _openAi);
    }
  }

  Future<void> saveGeminiKey(String key) async {
    _gemini = key.trim();
    final prefs = await SharedPreferences.getInstance();
    if (_gemini.isEmpty) {
      await prefs.remove(_geminiKey);
    } else {
      await prefs.setString(_geminiKey, _gemini);
    }
  }

  Future<void> saveProvider(String provider) async {
    _provider = provider.trim().isEmpty ? 'auto' : provider.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, _provider);
  }

  Future<void> clearAll() async {
    _openAi = '';
    _gemini = '';
    _provider = 'auto';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_openAiKey);
    await prefs.remove(_geminiKey);
    await prefs.remove(_providerKey);
  }

  bool get hasAnyKey => _openAi.isNotEmpty || _gemini.isNotEmpty;
}
