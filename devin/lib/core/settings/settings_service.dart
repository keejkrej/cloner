import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _openAiKey = 'devin_openai_key';
  static const _githubToken = 'devin_github_token';
  static const _defaultRepoPath = 'devin_default_repo';

  Future<String?> getOpenAiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_openAiKey);
  }

  Future<void> setOpenAiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openAiKey, key);
  }

  Future<String?> getGithubToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_githubToken);
  }

  Future<void> setGithubToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_githubToken, token);
  }

  Future<String?> getDefaultRepoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultRepoPath);
  }

  Future<void> setDefaultRepoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultRepoPath, path);
  }
}
