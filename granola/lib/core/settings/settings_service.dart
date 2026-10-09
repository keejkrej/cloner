import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyDeepgramKey = 'granola_deepgram_api_key';
  static const _keyLlmKey = 'granola_llm_api_key';
  static const _keyLlmBaseUrl = 'granola_llm_base_url';
  static const _keyLlmModel = 'granola_llm_model';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  String get deepgramApiKey => _prefs.getString(_keyDeepgramKey) ?? '';
  Future<void> setDeepgramApiKey(String key) => _prefs.setString(_keyDeepgramKey, key.trim());

  String get llmApiKey => _prefs.getString(_keyLlmKey) ?? '';
  Future<void> setLlmApiKey(String key) => _prefs.setString(_keyLlmKey, key.trim());

  String get llmBaseUrl => _prefs.getString(_keyLlmBaseUrl) ?? 'https://openrouter.ai/api/v1';
  Future<void> setLlmBaseUrl(String url) => _prefs.setString(_keyLlmBaseUrl, url.trim());

  String get llmModel => _prefs.getString(_keyLlmModel) ?? 'anthropic/claude-3.5-sonnet';
  Future<void> setLlmModel(String model) => _prefs.setString(_keyLlmModel, model.trim());

  bool get hasLlmKey => llmApiKey.isNotEmpty;
  bool get hasSttKey => deepgramApiKey.isNotEmpty;
}
