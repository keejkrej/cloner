import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyApiKey = 'harvey_llm_api_key';
  static const _keyBaseUrl = 'harvey_llm_base_url';
  static const _keyModel = 'harvey_llm_model';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  String get apiKey => _prefs.getString(_keyApiKey) ?? '';
  Future<void> setApiKey(String key) => _prefs.setString(_keyApiKey, key.trim());

  String get baseUrl => _prefs.getString(_keyBaseUrl) ?? 'https://openrouter.ai/api/v1';
  Future<void> setBaseUrl(String url) => _prefs.setString(_keyBaseUrl, url.trim());

  String get model => _prefs.getString(_keyModel) ?? 'anthropic/claude-3.5-sonnet';
  Future<void> setModel(String model) => _prefs.setString(_keyModel, model.trim());

  bool get hasKey => apiKey.isNotEmpty;
}
