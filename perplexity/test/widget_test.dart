import 'package:flutter_test/flutter_test.dart';
import 'package:perplexity/features/rerank/rerank_service.dart';
import 'package:perplexity/features/search/models.dart';

void main() {
  test('SearchThread and SourceCard model serialization', () {
    final now = DateTime.now();
    final thread = SearchThread(
      id: 'thread-1',
      title: 'AI Architectures',
      createdAt: now,
      updatedAt: now,
    );

    final map = thread.toMap();
    final restored = SearchThread.fromMap(map);
    expect(restored.id, 'thread-1');
    expect(restored.title, 'AI Architectures');

    final source = SourceCard(
      id: 'src-1',
      threadId: 'thread-1',
      indexNum: 1,
      title: 'Source Title',
      url: 'https://example.com',
      snippet: 'This is a test snippet',
      score: 0.95,
    );
    final srcMap = source.toMap();
    final restoredSrc = SourceCard.fromMap(srcMap);
    expect(restoredSrc.indexNum, 1);
    expect(restoredSrc.score, 0.95);
  });

  test('Local reranker ranks relevant chunks higher', () async {
    final reranker = RerankService();
    final results = [
      RawSearchResult(
        title: 'Cooking Pasta',
        url: 'https://cooking.com',
        content: 'Boil water and add salt. Cook pasta for 10 minutes.',
      ),
      RawSearchResult(
        title: 'Quantum Computers in 2026',
        url: 'https://quantum.com',
        content: 'Quantum computing breakthroughs in error correction and logical qubits.',
      ),
    ];

    final reranked = await reranker.rerank(
      query: 'quantum computing qubits',
      rawResults: results,
      provider: 'local',
      apiKey: '',
      topK: 2,
    );

    expect(reranked.isNotEmpty, true);
    expect(reranked.first.title, 'Quantum Computers in 2026');
    expect(reranked.first.relevanceScore > 0.3, true);
  });
}
