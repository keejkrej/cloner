import 'package:flutter/material.dart';
import 'core/db/database_service.dart';
import 'core/settings/settings_service.dart';
import 'features/generator/workflow_generator_service.dart';
import 'features/runner/workflow_runner_service.dart';
import 'features/ui/zapier_home_screen.dart';
import 'features/workflows/workflow_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DatabaseService.instance;
  final settingsService = SettingsService();
  final repository = WorkflowRepository(dbService: dbService);
  final runnerService = WorkflowRunnerService(repository: repository);
  final generatorService = WorkflowGeneratorService(settingsService: settingsService);

  runApp(ZapierApp(
    repository: repository,
    runnerService: runnerService,
    generatorService: generatorService,
    settingsService: settingsService,
  ));
}

class ZapierApp extends StatelessWidget {
  final WorkflowRepository repository;
  final WorkflowRunnerService runnerService;
  final WorkflowGeneratorService generatorService;
  final SettingsService settingsService;

  const ZapierApp({
    super.key,
    required this.repository,
    required this.runnerService,
    required this.generatorService,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zapier AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.orange,
          secondary: Colors.deepOrangeAccent,
          surface: Color(0xFF1E1E24),
        ),
        scaffoldBackgroundColor: const Color(0xFF121216),
        cardColor: const Color(0xFF1A1A22),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16161D),
          elevation: 0,
        ),
      ),
      home: ZapierHomeScreen(
        repository: repository,
        runnerService: runnerService,
        generatorService: generatorService,
        settingsService: settingsService,
      ),
    );
  }
}
