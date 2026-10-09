import 'package:flutter_test/flutter_test.dart';
import 'package:gamma/core/settings/settings_service.dart';
import 'package:gamma/features/deck/deck_generator_service.dart';
import 'package:gamma/features/deck/models/deck.dart';
import 'package:gamma/features/deck/models/slide.dart';
import 'package:gamma/features/themes/deck_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Deck Theme Tests', () {
    test('4 distinct themes are available', () {
      expect(DeckTheme.themes.length, equals(4));
      final ids = DeckTheme.themes.map((t) => t.id).toList();
      expect(ids, containsAll(['modern_dark', 'minimal_light', 'midnight_nebula', 'warm_terracotta']));
    });

    test('getById returns correct theme or fallback', () {
      final theme = DeckTheme.getById('midnight_nebula');
      expect(theme.name, equals('Midnight Nebula'));
      expect(theme.isDark, isTrue);

      final fallback = DeckTheme.getById('non_existent');
      expect(fallback.id, equals('modern_dark'));
    });
  });

  group('Deck & Slide Serialization Tests', () {
    test('Slide toMap and fromMap with all layout fields', () {
      const slide = Slide(
        id: 'slide_1',
        deckId: 'deck_1',
        slideOrder: 0,
        layout: 'two_column',
        title: 'Comparison Slide',
        subtitle: 'Key differences',
        bullets: ['Point A', 'Point B'],
        leftColumnTitle: 'Option A',
        leftColumnText: 'Description A',
        rightColumnTitle: 'Option B',
        rightColumnText: 'Description B',
        statNumber: '10x',
        statLabel: 'Faster speed',
        quoteText: 'To be or not to be',
        quoteAuthor: 'Shakespeare',
        imageUrl: 'https://example.com/img.jpg',
        imagePrompt: 'futuristic architecture',
      );

      final map = slide.toMap();
      final restored = Slide.fromMap(map);

      expect(restored.id, equals(slide.id));
      expect(restored.layoutType, equals(SlideLayout.twoColumn));
      expect(restored.title, equals('Comparison Slide'));
      expect(restored.bullets, equals(['Point A', 'Point B']));
      expect(restored.leftColumnTitle, equals('Option A'));
      expect(restored.statNumber, equals('10x'));
      expect(restored.quoteAuthor, equals('Shakespeare'));
    });

    test('Deck toMap and fromMap', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final deck = Deck(
        id: 'deck_1',
        title: 'Future of Computing',
        topic: 'Quantum Computing',
        themeId: 'warm_terracotta',
        slides: const [
          Slide(
            id: 's1',
            deckId: 'deck_1',
            slideOrder: 0,
            layout: 'title',
            title: 'Quantum Leap',
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final map = deck.toMap();
      final restored = Deck.fromMap(map, slides: deck.slides);

      expect(restored.id, equals(deck.id));
      expect(restored.topic, equals('Quantum Computing'));
      expect(restored.themeId, equals('warm_terracotta'));
      expect(restored.slides.length, equals(1));
    });
  });

  group('DeckGeneratorService Tests', () {
    test('Generate outline produces varied sensible slide layouts', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final generator = DeckGeneratorService(settings);

      final outline = await generator.generateOutline('Autonomous AI Agents');
      expect(outline.length, greaterThanOrEqualTo(5));
      expect(outline.first.layout, equals('title'));

      final layouts = outline.map((o) => o.layout).toSet();
      // Should contain at least 4 different layouts for variety
      expect(layouts.length, greaterThanOrEqualTo(4));
    });

    test('Generate full deck builds rich slide structures for all layouts', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final generator = DeckGeneratorService(settings);

      final outline = await generator.generateOutline('Space Colonization 2050');
      final deck = await generator.generateFullDeck(
        topic: 'Space Colonization 2050',
        outline: outline,
        themeId: 'midnight_nebula',
      );

      expect(deck.topic, equals('Space Colonization 2050'));
      expect(deck.themeId, equals('midnight_nebula'));
      expect(deck.slides.length, equals(outline.length));

      // Verify that specific slide layouts have their specific contents populated
      final bulletsSlide = deck.slides.firstWhere((s) => s.layoutType == SlideLayout.bullets);
      expect(bulletsSlide.bullets, isNotEmpty);

      final bigNumberSlide = deck.slides.firstWhere((s) => s.layoutType == SlideLayout.bigNumber);
      expect(bigNumberSlide.statNumber, isNotNull);
      expect(bigNumberSlide.statLabel, isNotNull);

      final twoColSlide = deck.slides.firstWhere((s) => s.layoutType == SlideLayout.twoColumn);
      expect(twoColSlide.leftColumnTitle, isNotNull);
      expect(twoColSlide.rightColumnTitle, isNotNull);

      final quoteSlide = deck.slides.firstWhere((s) => s.layoutType == SlideLayout.quote);
      expect(quoteSlide.quoteText, isNotNull);
      expect(quoteSlide.quoteAuthor, isNotNull);
    });
  });
}
