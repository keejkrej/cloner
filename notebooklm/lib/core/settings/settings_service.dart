import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _keyLlmApiKey = 'llm_api_key';
  static const _keyLlmBaseUrl = 'llm_base_url';
  static const _keyLlmModel = 'llm_model';
  static const _keyTtsApiKey = 'tts_api_key';
  static const _keyTtsVoiceA = 'tts_voice_a'; // Host 1 (e.g. 'alloy')
  static const _keyTtsVoiceB = 'tts_voice_b'; // Host 2 (e.g. 'echo')

  late SharedPreferences _prefs;

  String _llmApiKey = '';
  String _llmBaseUrl = 'https://api.openai.com/v1';
  String _llmModel = 'gpt-4o-mini';
  String _ttsApiKey = '';
  String _ttsVoiceA = 'alloy';
  String _ttsVoiceB = 'echo';

  String get llmApiKey => _llmApiKey;
  String get llmBaseUrl => _llmBaseUrl;
  String get llmModel => _llmModel;
  String get ttsApiKey => _ttsApiKey.isEmpty ? _llmApiKey : _ttsApiKey;
  String get ttsVoiceA => _ttsVoiceA;
  String get ttsVoiceB => _ttsVoiceB;

  bool get hasValidApiKey => _llmApiKey.trim().isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _llmApiKey = _prefs.getString(_keyLlmApiKey) ?? '';
    _llmBaseUrl = _prefs.getString(_keyLlmBaseUrl) ?? 'https://api.openai.com/v1';
    _llmModel = _prefs.getString(_keyLlmModel) ?? 'gpt-4o-mini';
    _ttsApiKey = _prefs.getString(_keyTtsApiKey) ?? '';
    _ttsVoiceA = _prefs.getString(_keyTtsVoiceA) ?? 'alloy';
    _ttsVoiceB = _prefs.getString(_keyTtsVoiceB) ?? 'echo';
    notifyListeners();
  }

  Future<void> saveSettings({
    required String llmApiKey,
    required String llmBaseUrl,
    required String llmModel,
    required String ttsApiKey,
    required String ttsVoiceA,
    required String ttsVoiceB,
  }) async {
    _llmApiKey = llmApiKey.trim();
    _llmBaseUrl = llmBaseUrl.trim().isEmpty ? 'https://api.openai.com/v1' : llmBaseUrl.trim();
    _llmModel = llmModel.trim().isEmpty ? 'gpt-4o-mini' : llmModel.trim();
    _ttsApiKey = ttsApiKey.trim();
    _ttsVoiceA = ttsVoiceA.trim().isEmpty ? 'alloy' : ttsVoiceA.trim();
    _ttsVoiceB = ttsVoiceB.trim().isEmpty ? 'echo' : ttsVoiceB.trim();

    await _prefs.setString(_keyLlmApiKey, _llmApiKey);
    await _prefs.setString(_keyLlmBaseUrl, _llmBaseUrl);
    await _prefs.setString(_keyLlmModel, _llmModel);
    await _prefs.setString(_keyTtsApiKey, _ttsApiKey);
    await _prefs.setString(_keyTtsVoiceA, _ttsVoiceA);
    await _prefs.setString(_keyTtsVoiceB, _ttsVoiceB);

    notifyListeners();
  }
}
