import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../deck/models/deck.dart';
import '../themes/deck_theme.dart';
import '../ui/slide_layouts/slide_renderer.dart';

class PresentationScreen extends StatefulWidget {
  final Deck deck;
  final DeckTheme initialTheme;
  final int initialSlideIndex;
  final void Function(DeckTheme newTheme)? onThemeChanged;

  const PresentationScreen({
    super.key,
    required this.deck,
    required this.initialTheme,
    this.initialSlideIndex = 0,
    this.onThemeChanged,
  });

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  late int _currentIndex;
  late DeckTheme _currentTheme;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialSlideIndex.clamp(0, widget.deck.slides.length - 1);
    _currentTheme = widget.initialTheme;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _nextSlide() {
    if (_currentIndex < widget.deck.slides.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _prevSlide() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _setTheme(DeckTheme theme) {
    setState(() => _currentTheme = theme);
    widget.onThemeChanged?.call(theme);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.pageDown) {
        _nextSlide();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.pageUp) {
        _prevSlide();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.deck.slides;
    if (slides.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No slides in deck. Exit'),
          ),
        ),
      );
    }

    final currentSlide = slides[_currentIndex];

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Centered 16:9 Presentation slide
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: KeyedSubtree(
                  key: ValueKey('${currentSlide.id}_${_currentTheme.id}'),
                  child: SlideRenderer(
                    slide: currentSlide,
                    theme: _currentTheme,
                    isInteractive: false,
                  ),
                ),
              ),
            ),

            // Top Floating Bar (Exit & Theme picker)
            Positioned(
              top: 20,
              right: 20,
              left: 20,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.deck.title,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  const Spacer(),
                  // Theme switcher menu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currentTheme.id,
                        dropdownColor: const Color(0xFF1E1E28),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        icon: const Icon(Icons.palette, size: 16, color: Colors.white70),
                        items: DeckTheme.themes.map((t) {
                          return DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) _setTheme(DeckTheme.getById(id));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Exit Fullscreen
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    tooltip: 'Exit Presentation (Esc)',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Bottom Navigation Overlay
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white),
                        tooltip: 'Previous Slide (Left Arrow)',
                        onPressed: _currentIndex > 0 ? _prevSlide : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_currentIndex + 1} / ${slides.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                        tooltip: 'Next Slide (Right Arrow / Space)',
                        onPressed: _currentIndex < slides.length - 1 ? _nextSlide : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
