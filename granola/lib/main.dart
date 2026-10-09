import 'package:flutter/material.dart';
import 'core/settings/settings_service.dart';
import 'features/meetings/meeting_repository.dart';
import 'features/notes/notes_enhancement_service.dart';
import 'features/stt/audio_transcription_service.dart';
import 'features/ui/meeting_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = await SettingsService.init();
  final repository = MeetingRepository();
  final transcriptionService = AudioTranscriptionService(settingsService);
  final enhancementService = NotesEnhancementService(settingsService);

  runApp(GranolaApp(
    settingsService: settingsService,
    repository: repository,
    transcriptionService: transcriptionService,
    enhancementService: enhancementService,
  ));
}

class GranolaApp extends StatelessWidget {
  final SettingsService settingsService;
  final MeetingRepository repository;
  final AudioTranscriptionService transcriptionService;
  final NotesEnhancementService enhancementService;

  const GranolaApp({
    super.key,
    required this.settingsService,
    required this.repository,
    required this.transcriptionService,
    required this.enhancementService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Granola AI Clone',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.teal,
          surface: const Color(0xFF161922),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F1118),
        useMaterial3: true,
      ),
      home: MeetingListScreen(
        settingsService: settingsService,
        repository: repository,
        transcriptionService: transcriptionService,
        enhancementService: enhancementService,
      ),
    );
  }
}
