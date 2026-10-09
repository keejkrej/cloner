import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/database_service.dart';
import '../../core/enhancer/prompt_enhancer.dart';
import '../../core/generator/image_generator.dart';
import '../../core/settings/settings_service.dart';
import 'models.dart';

class GalleryService extends ChangeNotifier {
  final SettingsService settingsService;
  late final PromptEnhancer enhancer;
  late final ImageGenerator generator;
  final _uuid = const Uuid();

  List<GeneratedImage> _images = [];
  bool _isEnhancing = false;
  bool _isGenerating = false;
  String _progressText = '';
  String _enhancedPrompt = '';
  String _aspectRatio = '1:1';

  GalleryService({required this.settingsService}) {
    enhancer = PromptEnhancer(settingsService: settingsService);
    generator = ImageGenerator(settingsService: settingsService);
  }

  List<GeneratedImage> get images => List.unmodifiable(_images);
  bool get isEnhancing => _isEnhancing;
  bool get isGenerating => _isGenerating;
  String get progressText => _progressText;
  String get enhancedPrompt => _enhancedPrompt;
  String get aspectRatio => _aspectRatio;

  void setAspectRatio(String ar) {
    _aspectRatio = ar;
    notifyListeners();
  }

  void updateEnhancedPrompt(String text) {
    _enhancedPrompt = text;
    notifyListeners();
  }

  Future<void> init() async {
    await loadGallery();
  }

  Future<void> loadGallery() async {
    final db = await DatabaseService.database;
    final rows = await db.query('generated_images', orderBy: 'created_at DESC');
    _images = rows.map((r) => GeneratedImage.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> enhance(String rawPrompt) async {
    final clean = rawPrompt.trim();
    if (clean.isEmpty || _isEnhancing) return;

    _isEnhancing = true;
    _progressText = 'Expanding prompt with Midjourney v6 aesthetics...';
    notifyListeners();

    try {
      final result = await enhancer.enhancePrompt(
        rawPrompt: clean,
        aspectRatio: _aspectRatio,
      );
      _enhancedPrompt = result;
    } finally {
      _isEnhancing = false;
      _progressText = '';
      notifyListeners();
    }
  }

  Future<void> generateGrid({
    required String rawPrompt,
    required String promptToUse,
  }) async {
    if (promptToUse.trim().isEmpty || _isGenerating) return;

    _isGenerating = true;
    _progressText = 'Synthesizing 4 aesthetic image variations...';
    notifyListeners();

    try {
      final savedPaths = await generator.generateGrid4(
        prompt: promptToUse,
        aspectRatio: _aspectRatio,
        onProgress: (current, total) {
          _progressText = 'Generating image $current of $total...';
          notifyListeners();
        },
      );

      final db = await DatabaseService.database;
      for (final path in savedPaths) {
        final img = GeneratedImage(
          id: _uuid.v4(),
          prompt: rawPrompt.trim().isEmpty ? promptToUse : rawPrompt.trim(),
          enhancedPrompt: promptToUse,
          aspectRatio: _aspectRatio,
          imagePath: path,
          createdAt: DateTime.now(),
        );

        await db.insert('generated_images', img.toMap());
        _images.insert(0, img);
      }
    } finally {
      _isGenerating = false;
      _progressText = '';
      notifyListeners();
    }
  }

  Future<void> deleteImage(String id) async {
    final idx = _images.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final img = _images[idx];
      try {
        final f = File(img.imagePath);
        if (await f.exists()) await f.delete();
      } catch (_) {}

      final db = await DatabaseService.database;
      await db.delete('generated_images', where: 'id = ?', whereArgs: [id]);
      _images.removeAt(idx);
      notifyListeners();
    }
  }
}
