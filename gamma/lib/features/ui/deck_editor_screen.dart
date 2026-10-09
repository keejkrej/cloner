import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../deck/deck_repository.dart';
import '../deck/models/deck.dart';
import '../deck/models/slide.dart';
import '../presentation/presentation_screen.dart';
import '../themes/deck_theme.dart';
import 'slide_layouts/slide_renderer.dart';

class DeckEditorScreen extends StatefulWidget {
  final Deck initialDeck;
  final DeckRepository repository;

  const DeckEditorScreen({
    super.key,
    required this.initialDeck,
    required this.repository,
  });

  @override
  State<DeckEditorScreen> createState() => _DeckEditorScreenState();
}

class _DeckEditorScreenState extends State<DeckEditorScreen> {
  late Deck _deck;
  late DeckTheme _theme;
  int _activeSlideIndex = 0;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _deck = widget.initialDeck;
    _theme = DeckTheme.getById(_deck.themeId);
  }

  Future<void> _updateTheme(DeckTheme theme) async {
    setState(() {
      _theme = theme;
      _deck = _deck.copyWith(themeId: theme.id);
    });
    await widget.repository.updateDeckTheme(_deck.id, theme.id);
  }

  Future<void> _changeSlideLayout(SlideLayout newLayout) async {
    if (_deck.slides.isEmpty) return;
    final current = _deck.slides[_activeSlideIndex];
    if (current.layout == newLayout.code) return;

    final updated = current.copyWith(layout: newLayout.code);
    final newSlides = List<Slide>.from(_deck.slides);
    newSlides[_activeSlideIndex] = updated;

    setState(() {
      _deck = _deck.copyWith(slides: newSlides);
    });
    await widget.repository.saveDeck(_deck);
  }

  Future<void> _addSlide() async {
    final newSlide = Slide(
      id: _uuid.v4(),
      deckId: _deck.id,
      slideOrder: _deck.slides.length,
      layout: 'bullets',
      title: 'New Slide ${_deck.slides.length + 1}',
      subtitle: 'Key takeaways and strategic points',
      bullets: [
        'First strategic point for this section.',
        'Secondary supporting insight or metric.',
        'Actionable conclusion for the audience.',
      ],
    );

    final newSlides = List<Slide>.from(_deck.slides)..add(newSlide);
    setState(() {
      _deck = _deck.copyWith(slides: newSlides);
      _activeSlideIndex = newSlides.length - 1;
    });
    await widget.repository.saveDeck(_deck);
  }

  Future<void> _deleteCurrentSlide() async {
    if (_deck.slides.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the only slide in the deck')),
      );
      return;
    }

    final newSlides = List<Slide>.from(_deck.slides)..removeAt(_activeSlideIndex);
    // Re-index orders
    for (int i = 0; i < newSlides.length; i++) {
      newSlides[i] = newSlides[i].copyWith(slideOrder: i);
    }

    setState(() {
      _deck = _deck.copyWith(slides: newSlides);
      if (_activeSlideIndex >= newSlides.length) {
        _activeSlideIndex = newSlides.length - 1;
      }
    });
    await widget.repository.saveDeck(_deck);
  }

  void _openPresentation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PresentationScreen(
          deck: _deck,
          initialTheme: _theme,
          initialSlideIndex: _activeSlideIndex,
          onThemeChanged: (newTheme) {
            _updateTheme(newTheme);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = _deck.slides;
    final currentSlide = slides.isNotEmpty ? slides[_activeSlideIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _deck.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              _deck.topic,
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          // Theme Switcher Dropdown (Instantly restyles entire deck!)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.palette_outlined, size: 18, color: Colors.amberAccent),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _theme.id,
                    dropdownColor: const Color(0xFF222230),
                    items: DeckTheme.themes.map((t) {
                      return DropdownMenuItem(
                        value: t.id,
                        child: Text(t.name, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (id) {
                      if (id != null) _updateTheme(DeckTheme.getById(id));
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Present button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: const Icon(Icons.play_arrow, size: 20),
            label: const Text('Present'),
            onPressed: _openPresentation,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Left Sidebar: Slide list / thumbnails
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Text(
                        'Slides',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        tooltip: 'Add Slide',
                        onPressed: _addSlide,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: slides.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final s = slides[index];
                      final isSelected = index == _activeSlideIndex;

                      return InkWell(
                        onTap: () => setState(() => _activeSlideIndex = index),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.amber.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.amberAccent : Colors.white12,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: isSelected ? Colors.amberAccent : Colors.white24,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      s.layoutType.label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected ? Colors.amberAccent : Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Center: Slide Preview & Quick Layout Toolbar
          Expanded(
            child: currentSlide == null
                ? const Center(child: Text('No slides'))
                : Column(
                    children: [
                      // Top Layout Quick-Switcher bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        color: Colors.white.withValues(alpha: 0.03),
                        child: Row(
                          children: [
                            const Text(
                              'Change Layout: ',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                            const SizedBox(width: 8),
                            Wrap(
                              spacing: 6,
                              children: SlideLayout.values.map((l) {
                                final isCurrent = currentSlide.layoutType == l;
                                return ChoiceChip(
                                  label: Text(l.label, style: const TextStyle(fontSize: 11)),
                                  selected: isCurrent,
                                  selectedColor: Colors.amberAccent.withValues(alpha: 0.3),
                                  onSelected: (_) => _changeSlideLayout(l),
                                );
                              }).toList(),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              tooltip: 'Delete Slide',
                              onPressed: _deleteCurrentSlide,
                            ),
                          ],
                        ),
                      ),

                      // Canvas Center (16:9 Slide Renderer)
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: SlideRenderer(
                              slide: currentSlide,
                              theme: _theme,
                            ),
                          ),
                        ),
                      ),

                      // Bottom Navigation bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        color: Colors.white.withValues(alpha: 0.03),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              tooltip: 'Previous Slide',
                              onPressed: _activeSlideIndex > 0
                                  ? () => setState(() => _activeSlideIndex--)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Slide ${_activeSlideIndex + 1} of ${slides.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              tooltip: 'Next Slide',
                              onPressed: _activeSlideIndex < slides.length - 1
                                  ? () => setState(() => _activeSlideIndex++)
                                  : null,
                            ),
                            const Spacer(),
                            Text(
                              'Theme: ${_theme.name}',
                              style: TextStyle(color: _theme.accentColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
