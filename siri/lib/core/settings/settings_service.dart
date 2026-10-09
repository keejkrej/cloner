import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _openAiKey = 'siri_openai_key';
  static const _ttsVoice = 'siri_tts_voice';
  static const _wakeWordEnabled = 'siri_wake_word_enabled';

  Future<String?> getOpenAiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_openAiKey);
  }

  Future<void> setOpenAiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openAiKey, key);
  }

  Future<String> getTtsVoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ttsVoice) ?? 'nova';
  }

  Future<void> setTtsVoice(String voice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ttsVoice, voice);
  }

  Future<bool> isWakeWordEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wakeWordEnabled) ?? true;
  }

  Future<void> setWakeWordEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wakeWordEnabled, enabled);
  }
}
