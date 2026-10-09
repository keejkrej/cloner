import '../../core/db/database_service.dart';
import 'models/deck.dart';
import 'models/slide.dart';

class DeckRepository {
  Future<List<Deck>> getAllDecks() async {
    final db = await DatabaseService.database;
    final deckRows = await db.query('decks', orderBy: 'updated_at DESC');

    final decks = <Deck>[];
    for (final row in deckRows) {
      final deckId = row['id'] as String;
      final slideRows = await db.query(
        'slides',
        where: 'deck_id = ?',
        whereArgs: [deckId],
        orderBy: 'slide_order ASC',
      );
      final slides = slideRows.map((s) => Slide.fromMap(s)).toList();
      decks.add(Deck.fromMap(row, slides: slides));
    }
    return decks;
  }

  Future<Deck?> getDeck(String deckId) async {
    final db = await DatabaseService.database;
    final deckRows = await db.query('decks', where: 'id = ?', whereArgs: [deckId]);
    if (deckRows.isEmpty) return null;

    final slideRows = await db.query(
      'slides',
      where: 'deck_id = ?',
      whereArgs: [deckId],
      orderBy: 'slide_order ASC',
    );
    final slides = slideRows.map((s) => Slide.fromMap(s)).toList();
    return Deck.fromMap(deckRows.first, slides: slides);
  }

  Future<void> saveDeck(Deck deck) async {
    final db = await DatabaseService.database;
    await db.transaction((txn) async {
      await txn.insert(
        'decks',
        deck.toMap(),
        conflictAlgorithm: null, // we replace below
      );

      await txn.delete('slides', where: 'deck_id = ?', whereArgs: [deck.id]);
      for (final slide in deck.slides) {
        await txn.insert('slides', slide.toMap());
      }
    });
  }

  Future<void> updateDeckTheme(String deckId, String themeId) async {
    final db = await DatabaseService.database;
    await db.update(
      'decks',
      {'theme_id': themeId, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [deckId],
    );
  }

  Future<void> deleteDeck(String deckId) async {
    final db = await DatabaseService.database;
    await db.delete('slides', where: 'deck_id = ?', whereArgs: [deckId]);
    await db.delete('decks', where: 'id = ?', whereArgs: [deckId]);
  }
}
