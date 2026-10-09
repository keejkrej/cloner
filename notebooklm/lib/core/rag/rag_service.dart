import 'dart:math';
import 'package:uuid/uuid.dart';
import '../db/database_service.dart';
import '../ingest/pdf_extractor.dart';
import '../../features/notebook/models.dart';

class RagService {
  final _uuid = const Uuid();

  /// Chunks page text and writes chunks to the database
  Future<List<DocumentChunk>> chunkAndIndexPages({
    required String notebookId,
    required String sourceId,
    required String sourceTitle,
    required List<PageText> pages,
  }) async {
    final db = await DatabaseService.database;
    final chunks = <DocumentChunk>[];

    int chunkIndex = 0;
    for (final page in pages) {
      final words = page.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.isEmpty) continue;

      const chunkSize = 150; // ~150 words per chunk
      const overlap = 30;

      for (int i = 0; i < words.length; i += (chunkSize - overlap)) {
        final end = min(i + chunkSize, words.length);
        final chunkText = words.sublist(i, end).join(' ');

        final chunk = DocumentChunk(
          id: _uuid.v4(),
          notebookId: notebookId,
          sourceId: sourceId,
          sourceTitle: sourceTitle,
          pageNumber: page.pageNumber,
          chunkIndex: chunkIndex++,
          content: chunkText,
        );

        chunks.add(chunk);
        await db.insert('chunks', chunk.toMap());

        if (end >= words.length) break;
      }
    }

    return chunks;
  }

  /// Retrieves the top-K chunks in a notebook matching the query
  Future<List<DocumentChunk>> retrieveRelevantChunks({
    required String notebookId,
    required String query,
    int topK = 6,
  }) async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'chunks',
      where: 'notebook_id = ?',
      whereArgs: [notebookId],
    );

    if (rows.isEmpty) return [];

    final allChunks = rows.map((r) => DocumentChunk.fromMap(r)).toList();
    final queryTokens = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2)
        .toSet();

    final scored = <MapEntry<DocumentChunk, double>>[];

    for (final chunk in allChunks) {
      final textLower = chunk.content.toLowerCase();
      double score = 0.0;

      // Exact phrase match
      if (textLower.contains(query.toLowerCase())) {
        score += 3.0;
      }

      // Title match
      if (chunk.sourceTitle.toLowerCase().contains(query.toLowerCase())) {
        score += 2.0;
      }

      // Token overlap
      int matched = 0;
      for (final t in queryTokens) {
        if (textLower.contains(t)) {
          matched++;
          score += 1.0;
        }
      }

      if (queryTokens.isNotEmpty && matched > 0) {
        score += (matched / queryTokens.length) * 2.0;
      }

      if (score > 0) {
        scored.add(MapEntry(chunk, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(topK).map((e) => e.key).toList();
  }
}
