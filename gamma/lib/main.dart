import 'package:flutter/material.dart';
import 'core/settings/settings_service.dart';
import 'features/deck/deck_generator_service.dart';
import 'features/deck/deck_repository.dart';
import 'features/ui/deck_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = await SettingsService.init();
  final repository = DeckRepository();
  final generatorService = DeckGeneratorService(settingsService);

  runApp(GammaApp(
    settingsService: settingsService,
    repository: repository,
    generatorService: generatorService,
  ));
}

class GammaApp extends StatelessWidget {
  final SettingsService settingsService;
  final DeckRepository repository;
  final DeckGeneratorService generatorService;

  const GammaApp({
    super.key,
    required this.settingsService,
    required this.repository,
    required this.generatorService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gamma Clone',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.amberAccent,
          secondary: Colors.amber,
          surface: const Color(0xFF191C26),
        ),
        scaffoldBackgroundColor: const Color(0xFF10131A),
        useMaterial3: true,
      ),
      home: DeckListScreen(
        settingsService: settingsService,
        repository: repository,
        generatorService: generatorService,
      ),
    );
  }
}
