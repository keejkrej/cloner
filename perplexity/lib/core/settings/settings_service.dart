import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _keyLlmApiKey = 'llm_api_key';
  static const _keyLlmBaseUrl = 'llm_base_url';
  static const _keyLlmModel = 'llm_model';
  static const _keySearchApiKey = 'search_api_key';
  static const _keySearchProvider = 'search_provider'; // 'tavily', 'brave', 'serper', 'duckduckgo'
  static const _keyRerankApiKey = 'rerank_api_key';
  static const _keyRerankProvider = 'rerank_provider'; // 'cohere', 'jina', 'local'

  late SharedPreferences _prefs;

  String _llmApiKey = '';
  String _llmBaseUrl = 'https://api.openai.com/v1';
  String _llmModel = 'gpt-4o-mini';
  String _searchApiKey = '';
  String _searchProvider = 'tavily';
  String _rerankApiKey = '';
  String _rerankProvider = 'local';

  String get llmApiKey => _llmApiKey;
  String get llmBaseUrl => _llmBaseUrl;
  String get llmModel => _llmModel;
  String get searchApiKey => _searchApiKey;
  String get searchProvider => _searchProvider;
  String get rerankApiKey => _rerankApiKey;
  String get rerankProvider => _rerankProvider;

  bool get hasLlmKey => _llmApiKey.trim().isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _llmApiKey = _prefs.getString(_keyLlmApiKey) ?? '';
    _llmBaseUrl = _prefs.getString(_keyLlmBaseUrl) ?? 'https://api.openai.com/v1';
    _llmModel = _prefs.getString(_keyLlmModel) ?? 'gpt-4o-mini';
    _searchApiKey = _prefs.getString(_keySearchApiKey) ?? '';
    _searchProvider = _prefs.getString(_keySearchProvider) ?? 'tavily';
    _rerankApiKey = _prefs.getString(_keyRerankApiKey) ?? '';
    _rerankProvider = _prefs.getString(_keyRerankProvider) ?? 'local';
    notifyListeners();
  }

  Future<void> saveSettings({
    required String llmApiKey,
    required String llmBaseUrl,
    required String llmModel,
    required String searchApiKey,
    required String searchProvider,
    required String rerankApiKey,
    required String rerankProvider,
  }) async {
    _llmApiKey = llmApiKey.trim();
    _llmBaseUrl = llmBaseUrl.trim().isEmpty ? 'https://api.openai.com/v1' : llmBaseUrl.trim();
    _llmModel = llmModel.trim().isEmpty ? 'gpt-4o-mini' : llmModel.trim();
    _searchApiKey = searchApiKey.trim();
    _searchProvider = searchProvider;
    _rerankApiKey = rerankApiKey.trim();
    _rerankProvider = rerankProvider;

    await _prefs.setString(_keyLlmApiKey, _llmApiKey);
    await _prefs.setString(_keyLlmBaseUrl, _llmBaseUrl);
    await _prefs.setString(_keyLlmModel, _llmModel);
    await _prefs.setString(_keySearchApiKey, _searchApiKey);
    await _prefs.setString(_keySearchProvider, _searchProvider);
    await _prefs.setString(_keyRerankApiKey, _rerankApiKey);
    await _prefs.setString(_keyRerankProvider, _rerankProvider);

    notifyListeners();
  }
}
