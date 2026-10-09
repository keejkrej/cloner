import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/settings/settings_service.dart';
import 'features/notebook/notebook_service.dart';
import 'features/ui/grounded_chat_view.dart';
import 'features/ui/notebook_sidebar.dart';
import 'features/ui/sources_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final settingsService = SettingsService();
  await settingsService.init();

  final notebookService = NotebookService(settingsService: settingsService);
  await notebookService.init();

  runApp(NotebookLMCloneApp(
    settingsService: settingsService,
    notebookService: notebookService,
  ));
}

class NotebookLMCloneApp extends StatelessWidget {
  final SettingsService settingsService;
  final NotebookService notebookService;

  const NotebookLMCloneApp({
    super.key,
    required this.settingsService,
    required this.notebookService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NotebookLM Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF141824),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C8CFF),
          surface: Color(0xFF1B202E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF11141E),
          elevation: 0,
        ),
      ),
      home: Scaffold(
        body: Row(
          children: [
            NotebookSidebar(
              notebookService: notebookService,
              settingsService: settingsService,
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF1F2436)),
            SourcesPanel(notebookService: notebookService),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF1F2436)),
            Expanded(
              child: GroundedChatView(notebookService: notebookService),
            ),
          ],
        ),
      ),
    );
  }
}
