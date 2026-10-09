import 'package:flutter/material.dart';
import 'core/settings/settings_service.dart';
import 'features/audio_player/audio_player_controller.dart';
import 'features/cloning/voice_clone_service.dart';
import 'features/history/history_service.dart';
import 'features/tts/tts_service.dart';
import 'features/ui/home_screen.dart';
import 'features/voices/voice_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = await SettingsService.init();
  final voiceService = VoiceService(settingsService);
  final ttsService = TtsService(settingsService);
  final cloneService = VoiceCloneService(settingsService, voiceService);
  final historyService = HistoryService();
  final audioController = AudioPlayerController();

  runApp(ElevenLabsApp(
    settingsService: settingsService,
    voiceService: voiceService,
    ttsService: ttsService,
    cloneService: cloneService,
    historyService: historyService,
    audioController: audioController,
  ));
}

class ElevenLabsApp extends StatelessWidget {
  final SettingsService settingsService;
  final VoiceService voiceService;
  final TtsService ttsService;
  final VoiceCloneService cloneService;
  final HistoryService historyService;
  final AudioPlayerController audioController;

  const ElevenLabsApp({
    super.key,
    required this.settingsService,
    required this.voiceService,
    required this.ttsService,
    required this.cloneService,
    required this.historyService,
    required this.audioController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElevenLabs Studio Clone',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.purpleAccent,
          secondary: Colors.purple,
          surface: const Color(0xFF1E1E28),
        ),
        scaffoldBackgroundColor: const Color(0xFF14141B),
        useMaterial3: true,
      ),
      home: HomeScreen(
        settingsService: settingsService,
        voiceService: voiceService,
        ttsService: ttsService,
        cloneService: cloneService,
        historyService: historyService,
        audioController: audioController,
      ),
    );
  }
}
