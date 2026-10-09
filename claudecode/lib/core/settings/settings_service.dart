import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _keyApiKey = 'api_key';
  static const _keyBaseUrl = 'base_url';
  static const _keyModel = 'model';
  static const _keyAutoApprove = 'auto_approve';

  late SharedPreferences _prefs;

  String _apiKey = '';
  String _baseUrl = 'https://api.openai.com/v1';
  String _model = 'gpt-4o';
  bool _autoApprove = false;

  String get apiKey => _apiKey;
  String get baseUrl => _baseUrl;
  String get model => _model;
  bool get autoApprove => _autoApprove;

  bool get hasValidApiKey => _apiKey.trim().isNotEmpty;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _apiKey = _prefs.getString(_keyApiKey) ?? '';
    _baseUrl = _prefs.getString(_keyBaseUrl) ?? 'https://api.openai.com/v1';
    _model = _prefs.getString(_keyModel) ?? 'gpt-4o';
    _autoApprove = _prefs.getBool(_keyAutoApprove) ?? false;
    notifyListeners();
  }

  Future<void> saveSettings({
    required String apiKey,
    required String baseUrl,
    required String model,
    required bool autoApprove,
  }) async {
    _apiKey = apiKey.trim();
    _baseUrl = baseUrl.trim().isEmpty ? 'https://api.openai.com/v1' : baseUrl.trim();
    _model = model.trim().isEmpty ? 'gpt-4o' : model.trim();
    _autoApprove = autoApprove;

    await _prefs.setString(_keyApiKey, _apiKey);
    await _prefs.setString(_keyBaseUrl, _baseUrl);
    await _prefs.setString(_keyModel, _model);
    await _prefs.setBool(_keyAutoApprove, _autoApprove);

    notifyListeners();
  }
}
