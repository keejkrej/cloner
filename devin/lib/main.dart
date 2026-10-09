import 'package:flutter/material.dart';
import 'core/settings/settings_service.dart';
import 'features/agent/devin_agent_service.dart';
import 'features/browser/devin_browser_service.dart';
import 'features/planner/planner_service.dart';
import 'features/pr/devin_pr_service.dart';
import 'features/shell/devin_shell_service.dart';
import 'features/ui/devin_workspace_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  final browserService = DevinBrowserService();
  final shellService = DevinShellService();
  final plannerService = PlannerService(settingsService: settingsService);
  final prBotService = DevinPrBotService(shellService: shellService, settingsService: settingsService);

  final agentService = DevinAgentService(
    plannerService: plannerService,
    browserService: browserService,
    shellService: shellService,
    prBotService: prBotService,
  );

  runApp(DevinApp(
    agentService: agentService,
    browserService: browserService,
    shellService: shellService,
    settingsService: settingsService,
  ));
}

class DevinApp extends StatelessWidget {
  final DevinAgentService agentService;
  final DevinBrowserService browserService;
  final DevinShellService shellService;
  final SettingsService settingsService;

  const DevinApp({
    super.key,
    required this.agentService,
    required this.browserService,
    required this.shellService,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Devin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1117),
        cardColor: const Color(0xFF161922),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.blueAccent,
          surface: Color(0xFF161922),
        ),
      ),
      home: DevinWorkspaceScreen(
        agentService: agentService,
        browserService: browserService,
        shellService: shellService,
        settingsService: settingsService,
      ),
    );
  }
}
