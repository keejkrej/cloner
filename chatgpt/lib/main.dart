import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'core/settings/settings_service.dart';
import 'features/chat/chat_service.dart';
import 'features/chat/chat_view.dart';
import 'features/history/history_sidebar.dart';
import 'features/memory/memory_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    try {
      databaseFactory = databaseFactoryFfiWebNoWebWorker;
    } catch (e) {
      debugPrint('Error setting web database factory: $e');
    }
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final settingsService = SettingsService();
  try {
    await settingsService.init();
  } catch (e) {
    debugPrint('Error initializing settings: $e');
  }

  final memoryService = MemoryService();
  try {
    await memoryService.loadMemories();
  } catch (e) {
    debugPrint('Error loading memories: $e');
  }

  final chatService = ChatService(
    settingsService: settingsService,
    memoryService: memoryService,
  );
  try {
    await chatService.init();
  } catch (e) {
    debugPrint('Error initializing chat service: $e');
  }

  runApp(ChatGPTCloneApp(
    settingsService: settingsService,
    memoryService: memoryService,
    chatService: chatService,
  ));
}

class ChatGPTCloneApp extends StatelessWidget {
  final SettingsService settingsService;
  final MemoryService memoryService;
  final ChatService chatService;

  const ChatGPTCloneApp({
    super.key,
    required this.settingsService,
    required this.memoryService,
    required this.chatService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatGPT Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF212121),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10A37F),
          surface: Color(0xFF202123),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF171717),
          elevation: 0,
        ),
      ),
      home: Scaffold(
        body: Row(
          children: [
            HistorySidebar(
              chatService: chatService,
              settingsService: settingsService,
              memoryService: memoryService,
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF2A2B32)),
            Expanded(
              child: ChatView(
                chatService: chatService,
                settingsService: settingsService,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
