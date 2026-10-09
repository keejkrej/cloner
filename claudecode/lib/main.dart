import 'package:flutter/material.dart';
import 'core/settings/settings_service.dart';
import 'features/agent/agent_loop.dart';
import 'features/ui/agent_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  await settingsService.init();

  final agentService = AgentService(settingsService: settingsService);

  runApp(ClaudeCodeApp(
    settingsService: settingsService,
    agentService: agentService,
  ));
}

class ClaudeCodeApp extends StatelessWidget {
  final SettingsService settingsService;
  final AgentService agentService;

  const ClaudeCodeApp({
    super.key,
    required this.settingsService,
    required this.agentService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Claude Code Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF141414),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFDA7756),
          surface: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
      ),
      home: AgentView(
        agentService: agentService,
        settingsService: settingsService,
      ),
    );
  }
}
