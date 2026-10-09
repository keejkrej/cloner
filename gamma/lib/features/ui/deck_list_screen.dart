import 'package:flutter/material.dart';
import '../../core/settings/settings_service.dart';
import '../deck/deck_generator_service.dart';
import '../deck/deck_repository.dart';
import '../deck/models/deck.dart';
import '../presentation/presentation_screen.dart';
import '../themes/deck_theme.dart';
import 'deck_editor_screen.dart';
import 'dialogs/create_deck_dialog.dart';
import 'dialogs/settings_dialog.dart';

class DeckListScreen extends StatefulWidget {
  final SettingsService settingsService;
  final DeckRepository repository;
  final DeckGeneratorService generatorService;

  const DeckListScreen({
    super.key,
    required this.settingsService,
    required this.repository,
    required this.generatorService,
  });

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  List<Deck> _decks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    setState(() => _isLoading = true);
    final decks = await widget.repository.getAllDecks();
    setState(() {
      _decks = decks;
      _isLoading = false;
    });
  }

  Future<void> _createNewDeck() async {
    final Deck? newDeck = await showDialog<Deck>(
      context: context,
      builder: (ctx) => CreateDeckDialog(
        generatorService: widget.generatorService,
      ),
    );

    if (newDeck != null) {
      await widget.repository.saveDeck(newDeck);
      await _loadDecks();
      if (mounted) {
        _openDeck(newDeck);
      }
    }
  }

  Future<void> _openDeck(Deck deck) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeckEditorScreen(
          initialDeck: deck,
          repository: widget.repository,
        ),
      ),
    );
    _loadDecks();
  }

  void _presentDirectly(Deck deck) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PresentationScreen(
          deck: deck,
          initialTheme: DeckTheme.getById(deck.themeId),
        ),
      ),
    );
  }

  Future<void> _deleteDeck(Deck deck) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Deck?'),
        content: Text('Are you sure you want to delete "${deck.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.repository.deleteDeck(deck.id);
      _loadDecks();
    }
  }

  Future<void> _openSettings() async {
    await showDialog(
      context: context,
      builder: (ctx) => SettingsDialog(settingsService: widget.settingsService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amberAccent),
            SizedBox(width: 10),
            Text(
              'Gamma Presentation Studio',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create New Deck'),
            onPressed: _createNewDeck,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _decks.isEmpty
              ? _buildEmptyState()
              : _buildDecksGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.slideshow, size: 64, color: Colors.amberAccent),
          ),
          const SizedBox(height: 20),
          const Text(
            'No presentation decks yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 450,
            child: Text(
              'Enter any topic to automatically generate an outline, smart multi-layout slides, and styled presentation decks with one click.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text(
              'Create Your First Deck',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onPressed: _createNewDeck,
          ),
        ],
      ),
    );
  }

  Widget _buildDecksGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.35,
      ),
      itemCount: _decks.length,
      itemBuilder: (context, index) {
        final deck = _decks[index];
        final theme = DeckTheme.getById(deck.themeId);

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          color: Theme.of(context).colorScheme.surface,
          child: InkWell(
            onTap: () => _openDeck(deck),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mini 16:9 header banner
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: theme.backgroundGradient,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: theme.accentColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          theme.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.accentColor,
                          ),
                        ),
                      ),
                      Text(
                        deck.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleFont(
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.topic,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.layers_outlined, size: 16, color: theme.accentColor),
                          const SizedBox(width: 6),
                          Text(
                            '${deck.slides.length} slides',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.play_circle_outline, size: 20),
                            tooltip: 'Present Fullscreen',
                            onPressed: () => _presentDirectly(deck),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                            tooltip: 'Delete',
                            onPressed: () => _deleteDeck(deck),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
