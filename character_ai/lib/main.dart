import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/settings/settings_service.dart';
import 'features/character/character_service.dart';
import 'features/ui/character_list_sidebar.dart';
import 'features/ui/chat_arena_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final settingsService = SettingsService();
  await settingsService.init();

  final characterService = CharacterService(settingsService: settingsService);
  await characterService.init();

  runApp(CharacterAICloneApp(
    settingsService: settingsService,
    characterService: characterService,
  ));
}

class CharacterAICloneApp extends StatelessWidget {
  final SettingsService settingsService;
  final CharacterService characterService;

  const CharacterAICloneApp({
    super.key,
    required this.settingsService,
    required this.characterService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Character AI Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF313338),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF5865F2),
          surface: Color(0xFF2B2D31),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1F22),
          elevation: 0,
        ),
      ),
      home: Scaffold(
        body: Row(
          children: [
            CharacterListSidebar(
              characterService: characterService,
              settingsService: settingsService,
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF1E1F22)),
            Expanded(
              child: ChatArenaView(characterService: characterService),
            ),
          ],
        ),
      ),
    );
  }
}
