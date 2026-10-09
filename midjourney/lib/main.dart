import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/settings/settings_service.dart';
import 'features/gallery/gallery_service.dart';
import 'features/ui/gallery_view.dart';
import 'features/ui/prompt_bar.dart';
import 'features/ui/settings_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final settingsService = SettingsService();
  await settingsService.init();

  final galleryService = GalleryService(settingsService: settingsService);
  await galleryService.init();

  runApp(MidjourneyCloneApp(
    settingsService: settingsService,
    galleryService: galleryService,
  ));
}

class MidjourneyCloneApp extends StatelessWidget {
  final SettingsService settingsService;
  final GalleryService galleryService;

  const MidjourneyCloneApp({
    super.key,
    required this.settingsService,
    required this.galleryService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Midjourney Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2463EB),
          surface: Color(0xFF181A20),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF14161C),
          elevation: 0,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          toolbarHeight: 44,
          title: Row(
            children: [
              const Icon(Icons.sailing, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Midjourney',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(width: 12),
              ListenableBuilder(
                listenable: galleryService,
                builder: (context, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2463EB).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${galleryService.images.length} images',
                      style: const TextStyle(color: Color(0xFF8AB4F8), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 18, color: Colors.white70),
              tooltip: 'Settings',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => SettingsDialog(settingsService: settingsService),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            PromptBar(galleryService: galleryService),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: GalleryView(galleryService: galleryService),
            ),
          ],
        ),
      ),
    );
  }
}
