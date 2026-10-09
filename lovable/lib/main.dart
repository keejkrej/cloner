import 'package:flutter/material.dart';
import 'core/settings/settings_service.dart';
import 'features/agent/coding_agent_service.dart';
import 'features/projects/project_repository.dart';
import 'features/ui/project_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = await SettingsService.init();
  final repository = ProjectRepository();
  final agentService = CodingAgentService(settingsService);

  runApp(LovableApp(
    settingsService: settingsService,
    repository: repository,
    agentService: agentService,
  ));
}

class LovableApp extends StatelessWidget {
  final SettingsService settingsService;
  final ProjectRepository repository;
  final CodingAgentService agentService;

  const LovableApp({
    super.key,
    required this.settingsService,
    required this.repository,
    required this.agentService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lovable Clone',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.blue,
          surface: const Color(0xFF161924),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        useMaterial3: true,
      ),
      home: ProjectListScreen(
        settingsService: settingsService,
        repository: repository,
        agentService: agentService,
      ),
    );
  }
}
