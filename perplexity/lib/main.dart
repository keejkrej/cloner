import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/settings/settings_service.dart';
import 'features/thread/thread_service.dart';
import 'features/ui/perplexity_view.dart';
import 'features/ui/thread_sidebar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final settingsService = SettingsService();
  await settingsService.init();

  final threadService = ThreadService(settingsService: settingsService);
  await threadService.init();

  runApp(PerplexityCloneApp(
    settingsService: settingsService,
    threadService: threadService,
  ));
}

class PerplexityCloneApp extends StatelessWidget {
  final SettingsService settingsService;
  final ThreadService threadService;

  const PerplexityCloneApp({
    super.key,
    required this.settingsService,
    required this.threadService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perplexity Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF191E24),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF20B8CD),
          surface: Color(0xFF1E242B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF13171C),
          elevation: 0,
        ),
      ),
      home: Scaffold(
        body: Row(
          children: [
            ThreadSidebar(
              threadService: threadService,
              settingsService: settingsService,
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF222B35)),
            Expanded(
              child: PerplexityView(
                threadService: threadService,
                settingsService: settingsService,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
