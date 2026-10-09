import 'package:flutter/material.dart';
import 'core/settings/settings_service.dart';
import 'features/agent/siri_agent_service.dart';
import 'features/stt/stt_service.dart';
import 'features/tts/tts_service.dart';
import 'features/ui/siri_overlay_screen.dart';
import 'features/wakeword/wake_word_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  final wakeWordService = WakeWordService();
  final sttService = SttService(settingsService: settingsService);
  final ttsService = TtsService(settingsService: settingsService);
  final agentService = SiriAgentService(
    settingsService: settingsService,
    sttService: sttService,
    ttsService: ttsService,
  );

  runApp(SiriApp(
    agentService: agentService,
    wakeWordService: wakeWordService,
    settingsService: settingsService,
  ));
}

class SiriApp extends StatelessWidget {
  final SiriAgentService agentService;
  final WakeWordService wakeWordService;
  final SettingsService settingsService;

  const SiriApp({
    super.key,
    required this.agentService,
    required this.wakeWordService,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siri Desktop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C0C12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFF007F),
          surface: Color(0xFF161622),
        ),
      ),
      home: SiriOverlayScreen(
        agentService: agentService,
        wakeWordService: wakeWordService,
        settingsService: settingsService,
      ),
    );
  }
}
