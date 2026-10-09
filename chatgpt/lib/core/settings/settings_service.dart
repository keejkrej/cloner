import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _keyApiKey = 'api_key';
  static const _keyBaseUrl = 'base_url';
  static const _keyModel = 'model';
  static const _keyExtractionModel = 'extraction_model';
  static const _keyMemoryEnabled = 'memory_enabled';

  late SharedPreferences _prefs;

  String _apiKey = '48188830f96246f7a15fdd4c168afb3c.iuWcpdWxke5JJMeQkZyes7rt';
  String _baseUrl = 'http://127.0.0.1:11434/v1';
  String _model = 'glm-5.3-flash:cloud';
  String _extractionModel = 'glm-5.3-flash:cloud';
  bool _memoryEnabled = true;

  String get apiKey => _apiKey;
  String get baseUrl => _baseUrl;
  String get model => _model;
  String get extractionModel => _extractionModel;
  bool get memoryEnabled => _memoryEnabled;

  bool get hasValidApiKey => _apiKey.trim().isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _apiKey = _prefs.getString(_keyApiKey) ?? '48188830f96246f7a15fdd4c168afb3c.iuWcpdWxke5JJMeQkZyes7rt';
    _baseUrl = _prefs.getString(_keyBaseUrl) ?? 'http://127.0.0.1:11434/v1';
    _model = _prefs.getString(_keyModel) ?? 'glm-5.3-flash:cloud';
    _extractionModel = _prefs.getString(_keyExtractionModel) ?? 'glm-5.3-flash:cloud';
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
