import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _keyApiKey = 'api_key';
  static const _keyBaseUrl = 'base_url';
  static const _keyChatModel = 'chat_model';
  static const _keyFimModel = 'fim_model';
  static const _keyEmbeddingModel = 'embedding_model';

  late SharedPreferences _prefs;

  String _apiKey = '';
  String _baseUrl = 'https://api.openai.com/v1';
  String _chatModel = 'gpt-4o-mini';
  String _fimModel = 'gpt-4o-mini';
  String _embeddingModel = 'text-embedding-3-small';

  String get apiKey => _apiKey;
  String get baseUrl => _baseUrl;
  String get chatModel => _chatModel;
  String get fimModel => _fimModel;
  String get embeddingModel => _embeddingModel;

  bool get hasValidApiKey => _apiKey.trim().isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _apiKey = _prefs.getString(_keyApiKey) ?? '';
    _baseUrl = _prefs.getString(_keyBaseUrl) ?? 'https://api.openai.com/v1';
    _chatModel = _prefs.getString(_keyChatModel) ?? 'gpt-4o-mini';
    _fimModel = _prefs.getString(_keyFimModel) ?? 'gpt-4o-mini';
    _embeddingModel = _prefs.getString(_keyEmbeddingModel) ?? 'text-embedding-3-small';
    notifyListeners();
  }

  Future<void> saveSettings({
    required String apiKey,
    required String baseUrl,
    required String chatModel,
    required String fimModel,
    required String embeddingModel,
  }) async {
    _apiKey = apiKey.trim();
    _baseUrl = baseUrl.trim().isEmpty ? 'https://api.openai.com/v1' : baseUrl.trim();
    _chatModel = chatModel.trim().isEmpty ? 'gpt-4o-mini' : chatModel.trim();
    _fimModel = fimModel.trim().isEmpty ? 'gpt-4o-mini' : fimModel.trim();
    _embeddingModel = embeddingModel.trim().isEmpty ? 'text-embedding-3-small' : embeddingModel.trim();

    await _prefs.setString(_keyApiKey, _apiKey);
    await _prefs.setString(_keyBaseUrl, _baseUrl);
    await _prefs.setString(_keyChatModel, _chatModel);
    await _prefs.setString(_keyFimModel, _fimModel);
    await _prefs.setString(_keyEmbeddingModel, _embeddingModel);

    notifyListeners();
  }
}
