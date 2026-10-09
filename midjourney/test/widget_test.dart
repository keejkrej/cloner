import 'package:flutter_test/flutter_test.dart';
import 'package:midjourney/core/enhancer/prompt_enhancer.dart';
import 'package:midjourney/core/settings/settings_service.dart';
import 'package:midjourney/features/gallery/models.dart';

void main() {
  test('GeneratedImage model serialization', () {
    final now = DateTime.now();
    final img = GeneratedImage(
      id: 'img-1',
      prompt: 'cyberpunk street',
      enhancedPrompt: 'cyberpunk street at night with neon lights --ar 16:9',
      aspectRatio: '16:9',
      imagePath: 'C:/fake/path.jpg',
      createdAt: now,
    );

    final map = img.toMap();
    final restored = GeneratedImage.fromMap(map);
    expect(restored.id, 'img-1');
    expect(restored.aspectRatio, '16:9');
    expect(restored.prompt, 'cyberpunk street');
  });

  test('PromptEnhancer fallback produces valid aspect ratio string', () async {
    final settings = SettingsService();
    final enhancer = PromptEnhancer(settingsService: settings);

    final result = await enhancer.enhancePrompt(
      rawPrompt: 'solitary astronaut on mars',
      aspectRatio: '16:9',
    );

    expect(result.contains('--ar 16:9'), true);
    expect(result.contains('solitary astronaut on mars'), true);
  });
}
