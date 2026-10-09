import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siri/core/settings/settings_service.dart';
import 'package:siri/features/agent/siri_agent_service.dart';
import 'package:siri/features/stt/stt_service.dart';
import 'package:siri/features/tools/tools_registry.dart';
import 'package:siri/features/tts/tts_service.dart';
import 'package:siri/features/wakeword/wake_word_service.dart';

// Test TTS that records spoken strings without needing native audio hardware
class FakeTtsService extends TtsService {
  final List<String> spokenHistory = [];

  @override
  Future<void> speak(String text) async {
    spokenHistory.add(text);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('WakeWordService Tests', () {
    test('Starts listening, maintains idle state, and triggers wake event', () async {
      final wakeService = WakeWordService();
      bool wakeDetected = false;

      final sub = wakeService.onWakeWordDetected.listen((_) {
        wakeDetected = true;
      });

      expect(wakeService.isListening, isFalse);
      wakeService.startListening();
      expect(wakeService.isListening, isTrue);

      wakeService.triggerWake();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(wakeDetected, isTrue);

      wakeService.stopListening();
      expect(wakeService.isListening, isFalse);
      await sub.cancel();
      wakeService.dispose();
    });
  });

  group('Siri Tools Tests', () {
    test('OpenAppTool executes for Spotify', () async {
      final tool = OpenAppTool();
      final res = await tool.execute({'app_name': 'Spotify'});

      expect(res.success, isTrue);
      expect(res.toolType, 'app');
      expect(res.speechResponse, contains('Spotify'));
      expect(res.data['app_name'], 'Spotify');
    });

    test('OpenUrlTool executes for web link', () async {
      final tool = OpenUrlTool();
      final res = await tool.execute({'url': 'https://apple.com'});

      expect(res.success, isTrue);
      expect(res.toolType, 'url');
      expect(res.data['url'], 'https://apple.com');
    });

    test('GetWeatherTool returns weather data for Berlin', () async {
      final tool = GetWeatherTool();
      final res = await tool.execute({'city': 'Berlin'});

      expect(res.success, isTrue);
      expect(res.toolType, 'weather');
      expect(res.data['city'], contains('Berlin'));
      expect(res.data['temperature'], isNotNull);
      expect(res.speechResponse, contains('degrees Celsius'));
    });

    test('SetTimerTool sets 5 minute timer', () async {
      final tool = SetTimerTool();
      final res = await tool.execute({'seconds': 300, 'label': 'Tea'});

      expect(res.success, isTrue);
      expect(res.toolType, 'timer');
      expect(res.data['total_seconds'], 300);
      expect(res.speechResponse, contains('5 minutes'));
    });

    test('SystemInfoTool returns OS health', () async {
      final tool = SystemInfoTool();
      final res = await tool.execute({});

      expect(res.success, isTrue);
      expect(res.toolType, 'system');
      expect(res.speechResponse, contains('cores'));
    });
  });

  group('SiriAgentService End-to-End Tests', () {
    test('"Open Spotify" invokes open_app and speaks aloud', () async {
      final fakeTts = FakeTtsService();
      final agent = SiriAgentService(
        settingsService: SettingsService(),
        sttService: SttService(),
        ttsService: fakeTts,
      );

      final result = await agent.handleQuery('Open Spotify');

      expect(result.toolType, 'app');
      expect(result.displayText, contains('Spotify'));
      expect(fakeTts.spokenHistory.length, 1);
      expect(fakeTts.spokenHistory.first, contains('Spotify'));
    });

    test('"Weather in Berlin?" invokes get_weather and speaks aloud', () async {
      final fakeTts = FakeTtsService();
      final agent = SiriAgentService(
        settingsService: SettingsService(),
        sttService: SttService(),
        ttsService: fakeTts,
      );

      final result = await agent.handleQuery('Weather in Berlin?');

      expect(result.toolType, 'weather');
      expect(result.toolData['temperature'], isNotNull);
      expect(fakeTts.spokenHistory.length, 1);
      expect(fakeTts.spokenHistory.first, contains('Berlin'));
    });

    test('"Timer for 5 minutes" sets countdown and speaks aloud', () async {
      final fakeTts = FakeTtsService();
      final agent = SiriAgentService(
        settingsService: SettingsService(),
        sttService: SttService(),
        ttsService: fakeTts,
      );

      final result = await agent.handleQuery('Timer for 5 minutes');

      expect(result.toolType, 'timer');
      expect(result.toolData['total_seconds'], 300);
      expect(fakeTts.spokenHistory.length, 1);
      expect(fakeTts.spokenHistory.first, contains('5 minutes'));
    });
  });
}
