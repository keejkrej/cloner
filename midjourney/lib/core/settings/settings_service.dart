import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _keyLlmApiKey = 'llm_api_key';
  static const _keyLlmBaseUrl = 'llm_base_url';
  static const _keyLlmModel = 'llm_model';
  static const _keyImageApiKey = 'image_api_key';
  static const _keyImageProvider = 'image_provider'; // 'pollinations', 'dalle', 'replicate'

  late SharedPreferences _prefs;

  String _llmApiKey = '';
  String _llmBaseUrl = 'https://api.openai.com/v1';
  String _llmModel = 'gpt-4o-mini';
  String _imageApiKey = '';
  String _imageProvider = 'pollinations';

  String get llmApiKey => _llmApiKey;
  String get llmBaseUrl => _llmBaseUrl;
  String get llmModel => _llmModel;
  String get imageApiKey => _imageApiKey.isEmpty ? _llmApiKey : _imageApiKey;
  String get imageProvider => _imageProvider;

  bool get hasLlmKey => _llmApiKey.trim().isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _llmApiKey = _prefs.getString(_keyLlmApiKey) ?? '';
    _llmBaseUrl = _prefs.getString(_keyLlmBaseUrl) ?? 'https://api.openai.com/v1';
    _llmModel = _prefs.getString(_keyLlmModel) ?? 'gpt-4o-mini';
    _imageApiKey = _prefs.getString(_keyImageApiKey) ?? '';
    _imageProvider = _prefs.getString(_keyImageProvider) ?? 'pollinations';
    notifyListeners();
  }

  Future<void> saveSettings({
    required String llmApiKey,
    required String llmBaseUrl,
    required String llmModel,
    required String imageApiKey,
    required String imageProvider,
  }) async {
    _llmApiKey = llmApiKey.trim();
    _llmBaseUrl = llmBaseUrl.trim().isEmpty ? 'https://api.openai.com/v1' : llmBaseUrl.trim();
    _llmModel = llmModel.trim().isEmpty ? 'gpt-4o-mini' : llmModel.trim();
    _imageApiKey = imageApiKey.trim();
    _imageProvider = imageProvider;

    await _prefs.setString(_keyLlmApiKey, _llmApiKey);
    await _prefs.setString(_keyLlmBaseUrl, _llmBaseUrl);
    await _prefs.setString(_keyLlmModel, _llmModel);
    await _prefs.setString(_keyImageApiKey, _imageApiKey);
    await _prefs.setString(_keyImageProvider, _imageProvider);

    notifyListeners();
  }
}
