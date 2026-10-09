import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _keyLlmApiKey = 'llm_api_key';
  static const _keyLlmBaseUrl = 'llm_base_url';
  static const _keyLlmModel = 'llm_model';
  static const _keyTtsApiKey = 'tts_api_key';
  static const _keySttApiKey = 'stt_api_key';
  static const _keyAutoPlayVoice = 'auto_play_voice';

  late SharedPreferences _prefs;

  String _llmApiKey = '';
  String _llmBaseUrl = 'https://api.openai.com/v1';
  String _llmModel = 'gpt-4o-mini';
  String _ttsApiKey = '';
  String _sttApiKey = '';
  bool _autoPlayVoice = true;

  String get llmApiKey => _llmApiKey;
  String get llmBaseUrl => _llmBaseUrl;
  String get llmModel => _llmModel;
  String get ttsApiKey => _ttsApiKey.isEmpty ? _llmApiKey : _ttsApiKey;
  String get sttApiKey => _sttApiKey.isEmpty ? _llmApiKey : _sttApiKey;
  bool get autoPlayVoice => _autoPlayVoice;

  bool get hasValidApiKey => _llmApiKey.trim().isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _llmApiKey = _prefs.getString(_keyLlmApiKey) ?? '';
    _llmBaseUrl = _prefs.getString(_keyLlmBaseUrl) ?? 'https://api.openai.com/v1';
    _llmModel = _prefs.getString(_keyLlmModel) ?? 'gpt-4o-mini';
    _ttsApiKey = _prefs.getString(_keyTtsApiKey) ?? '';
    _sttApiKey = _prefs.getString(_keySttApiKey) ?? '';
    _autoPlayVoice = _prefs.getBool(_keyAutoPlayVoice) ?? true;
    notifyListeners();
  }

  Future<void> saveSettings({
    required String llmApiKey,
    required String llmBaseUrl,
    required String llmModel,
    required String ttsApiKey,
    required String sttApiKey,
    required bool autoPlayVoice,
  }) async {
    _llmApiKey = llmApiKey.trim();
    _llmBaseUrl = llmBaseUrl.trim().isEmpty ? 'https://api.openai.com/v1' : llmBaseUrl.trim();
    _llmModel = llmModel.trim().isEmpty ? 'gpt-4o-mini' : llmModel.trim();
    _ttsApiKey = ttsApiKey.trim();
    _sttApiKey = sttApiKey.trim();
    _autoPlayVoice = autoPlayVoice;

    await _prefs.setString(_keyLlmApiKey, _llmApiKey);
    await _prefs.setString(_keyLlmBaseUrl, _llmBaseUrl);
    await _prefs.setString(_keyLlmModel, _llmModel);
    await _prefs.setString(_keyTtsApiKey, _ttsApiKey);
    await _prefs.setString(_keySttApiKey, _sttApiKey);
    await _prefs.setBool(_keyAutoPlayVoice, _autoPlayVoice);

    notifyListeners();
  }
}
