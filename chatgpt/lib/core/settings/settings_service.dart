import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _keyApiKey = 'api_key';
  static const _keyBaseUrl = 'base_url';
  static const _keyModel = 'model';
  static const _keyExtractionModel = 'extraction_model';
  static const _keyMemoryEnabled = 'memory_enabled';

  late SharedPreferences _prefs;

  String _apiKey = '';
  String _baseUrl = 'https://api.openai.com/v1';
  String _model = 'gpt-4o-mini';
  String _extractionModel = 'gpt-4o-mini';
  bool _memoryEnabled = true;

  String get apiKey => _apiKey;
  String get baseUrl => _baseUrl;
  String get model => _model;
  String get extractionModel => _extractionModel;
  bool get memoryEnabled => _memoryEnabled;

  bool get hasValidApiKey => _apiKey.trim().isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _apiKey = _prefs.getString(_keyApiKey) ?? '';
    _baseUrl = _prefs.getString(_keyBaseUrl) ?? 'https://api.openai.com/v1';
    _model = _prefs.getString(_keyModel) ?? 'gpt-4o-mini';
    _extractionModel = _prefs.getString(_keyExtractionModel) ?? 'gpt-4o-mini';
    _memoryEnabled = _prefs.getBool(_keyMemoryEnabled) ?? true;
    notifyListeners();
  }

  Future<void> saveSettings({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String extractionModel,
    required bool memoryEnabled,
  }) async {
    _apiKey = apiKey.trim();
    _baseUrl = baseUrl.trim().isEmpty ? 'https://api.openai.com/v1' : baseUrl.trim();
    _model = model.trim().isEmpty ? 'gpt-4o-mini' : model.trim();
    _extractionModel = extractionModel.trim().isEmpty ? 'gpt-4o-mini' : extractionModel.trim();
    _memoryEnabled = memoryEnabled;

    await _prefs.setString(_keyApiKey, _apiKey);
    await _prefs.setString(_keyBaseUrl, _baseUrl);
    await _prefs.setString(_keyModel, _model);
    await _prefs.setString(_keyExtractionModel, _extractionModel);
    await _prefs.setBool(_keyMemoryEnabled, _memoryEnabled);

    notifyListeners();
  }
}
