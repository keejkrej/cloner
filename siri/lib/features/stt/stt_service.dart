import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/settings/settings_service.dart';

class SttService {
  final SettingsService _settingsService;
  final http.Client? client;

  SttService({SettingsService? settingsService, this.client})
      : _settingsService = settingsService ?? SettingsService();

  /// Transcribes recorded audio file or falls back to text processing
  Future<String> transcribeAudioFile(File audioFile) async {
    final apiKey = await _settingsService.getOpenAiKey();
    if (apiKey != null && apiKey.trim().isNotEmpty && await audioFile.exists()) {
      try {
        final httpClient = client ?? http.Client();
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
        );
        request.headers['Authorization'] = 'Bearer $apiKey';
        request.fields['model'] = 'whisper-1';
        request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));

        final streamed = await httpClient.send(request).timeout(const Duration(seconds: 20));
        final response = await http.Response.fromStream(streamed);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return (data['text'] as String).trim();
        }
      } catch (_) {
        // Fall back to clean transcript
      }
    }
    return '';
  }

  /// Processes text speech input directly
  Future<String> processSpeechText(String spokenText) async {
    return spokenText.trim();
  }
}
