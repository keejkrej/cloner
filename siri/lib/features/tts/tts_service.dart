import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../core/settings/settings_service.dart';

class TtsService {
  final SettingsService _settingsService;
  final http.Client? client;
  AudioPlayer? audioPlayer;

  final _speakingController = StreamController<bool>.broadcast();
  Stream<bool> get onSpeakingChanged => _speakingController.stream;
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  TtsService({SettingsService? settingsService, this.client, this.audioPlayer})
      : _settingsService = settingsService ?? SettingsService();

  AudioPlayer get player => audioPlayer ??= AudioPlayer();

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    _isSpeaking = true;
    _speakingController.add(true);

    final apiKey = await _settingsService.getOpenAiKey();
    final voice = await _settingsService.getTtsVoice();

    bool spokenWithOpenAi = false;
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        final httpClient = client ?? http.Client();
        final res = await httpClient.post(
          Uri.parse('https://api.openai.com/v1/audio/speech'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'tts-1',
            'input': text,
            'voice': voice,
          }),
        ).timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/siri_tts_reply.mp3');
          await tempFile.writeAsBytes(res.bodyBytes);

          final completer = Completer<void>();
          final sub = player.onPlayerComplete.listen((_) {
            if (!completer.isCompleted) completer.complete();
          });

          await player.play(DeviceFileSource(tempFile.path));
          await completer.future.timeout(const Duration(seconds: 20), onTimeout: () {});
          await sub.cancel();
          spokenWithOpenAi = true;
        }
      } catch (_) {
        spokenWithOpenAi = false;
      }
    }

    if (!spokenWithOpenAi) {
      // Local Windows Speech Synthesis fallback (SAPI via powershell / command)
      await _speakNativeWindows(text);
    }

    _isSpeaking = false;
    _speakingController.add(false);
  }

  Future<void> _speakNativeWindows(String text) async {
    if (Platform.isWindows) {
      try {
        // Sanitize single quotes and newlines
        final sanitized = text.replaceAll("'", "''").replaceAll('\n', ' ');
        final command = "(New-Object -ComObject SAPI.SpVoice).Speak('$sanitized')";
        await Process.run('powershell', ['-NoProfile', '-NonInteractive', '-Command', command])
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Speech synthesis timeout or simulation
      }
    } else {
      // Simulate playback time for other platforms/tests
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  Future<void> stop() async {
    await audioPlayer?.stop();
    _isSpeaking = false;
    _speakingController.add(false);
  }

  void dispose() {
    audioPlayer?.dispose();
    _speakingController.close();
  }
}
