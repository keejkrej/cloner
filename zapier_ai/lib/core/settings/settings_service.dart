import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _openAiKey = 'zapier_openai_key';
  static const _geminiKey = 'zapier_gemini_key';
  static const _anthropicKey = 'zapier_anthropic_key';
  static const _discordWebhookUrl = 'zapier_discord_webhook';
  static const _slackWebhookUrl = 'zapier_slack_webhook';
  static const _emailFrom = 'zapier_email_from';

  Future<String?> getOpenAiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_openAiKey);
  }

  Future<void> setOpenAiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openAiKey, key);
  }

  Future<String?> getGeminiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiKey);
  }

  Future<void> setGeminiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKey, key);
  }

  Future<String?> getAnthropicKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_anthropicKey);
  }

  Future<void> setAnthropicKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_anthropicKey, key);
  }

  Future<String?> getDiscordWebhook() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_discordWebhookUrl);
  }

  Future<void> setDiscordWebhook(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_discordWebhookUrl, url);
  }

  Future<String?> getSlackWebhook() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_slackWebhookUrl);
  }

  Future<void> setSlackWebhook(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_slackWebhookUrl, url);
  }

  Future<String?> getEmailFrom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailFrom);
  }

  Future<void> setEmailFrom(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailFrom, email);
  }
}
