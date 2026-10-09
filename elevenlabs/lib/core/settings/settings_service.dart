import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyElevenLabsKey = 'elevenlabs_api_key';
  static const _keyOpenAiKey = 'openai_api_key';
  static const _keyModelId = 'elevenlabs_model_id';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  String get elevenLabsApiKey => _prefs.getString(_keyElevenLabsKey) ?? '';
  Future<void> setElevenLabsApiKey(String key) => _prefs.setString(_keyElevenLabsKey, key.trim());

  String get openAiApiKey => _prefs.getString(_keyOpenAiKey) ?? '';
  Future<void> setOpenAiApiKey(String key) => _prefs.setString(_keyOpenAiKey, key.trim());

  String get modelId => _prefs.getString(_keyModelId) ?? 'eleven_multilingual_v2';
  Future<void> setModelId(String id) => _prefs.setString(_keyModelId, id.trim());

  bool get hasKey => elevenLabsApiKey.isNotEmpty || openAiApiKey.isNotEmpty;
}
