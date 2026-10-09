import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../search/models.dart';

class RerankService {
  Future<List<RerankedChunk>> rerank({
    required String query,
    required List<RawSearchResult> rawResults,
    required String provider,
    required String apiKey,
    int topK = 6,
  }) async {
    if (rawResults.isEmpty) return [];

    // First break raw search results into chunks if they are long
    final chunks = <RerankedChunk>[];
    for (int i = 0; i < rawResults.length; i++) {
      final res = rawResults[i];
      final splitChunks = _chunkText(res.content, maxWords: 120);
      for (final textChunk in splitChunks) {
        chunks.add(RerankedChunk(
          sourceIndex: i + 1,
          title: res.title,
          url: res.url,
          text: textChunk,
          relevanceScore: 0.0,
        ));
      }
    }

    if (chunks.isEmpty) return [];

    if (provider == 'cohere' && apiKey.isNotEmpty) {
      try {
        return await _rerankCohere(query, chunks, apiKey, topK);
      } catch (e) {
        // Fallback to local reranker on error
      }
    } else if (provider == 'jina' && apiKey.isNotEmpty) {
      try {
        return await _rerankJina(query, chunks, apiKey, topK);
      } catch (e) {
        // Fallback to local reranker on error
      }
    }

    return _rerankLocal(query, chunks, topK);
  }

  List<String> _chunkText(String text, {int maxWords = 120}) {
    final words = text.split(RegExp(r'\s+'));
    if (words.length <= maxWords) return [text];

    final chunks = <String>[];
    for (int i = 0; i < words.length; i += maxWords - 20) {
      final end = min(i + maxWords, words.length);
      chunks.add(words.sublist(i, end).join(' '));
      if (end >= words.length) break;
    }
    return chunks;
  }

  Future<List<RerankedChunk>> _rerankCohere(
    String query,
    List<RerankedChunk> chunks,
    String apiKey,
    int topK,
  ) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('https://api.cohere.com/v1/rerank'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'rerank-english-v3.0',
          'query': query,
          'documents': chunks.map((c) => c.text).toList(),
          'top_n': min(topK, chunks.length),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Cohere error (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body);
      final results = json['results'] as List<dynamic>? ?? [];
      final reranked = <RerankedChunk>[];

      for (final r in results) {
        final idx = r['index'] as int;
        final score = (r['relevance_score'] as num).toDouble();
        final original = chunks[idx];
        reranked.add(RerankedChunk(
          sourceIndex: original.sourceIndex,
          title: original.title,
          url: original.url,
          text: original.text,
          relevanceScore: score,
        ));
      }
      return reranked;
    } finally {
      client.close();
    }
  }

  Future<List<RerankedChunk>> _rerankJina(
    String query,
    List<RerankedChunk> chunks,
    String apiKey,
    int topK,
  ) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('https://api.jina.ai/v1/rerank'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'jina-reranker-v2-base-multilingual',
          'query': query,
          'documents': chunks.map((c) => c.text).toList(),
          'top_n': min(topK, chunks.length),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Jina error (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body);
      final results = json['results'] as List<dynamic>? ?? [];
      final reranked = <RerankedChunk>[];

      for (final r in results) {
        final idx = r['index'] as int;
        final score = (r['relevance_score'] as num).toDouble();
        final original = chunks[idx];
        reranked.add(RerankedChunk(
          sourceIndex: original.sourceIndex,
          title: original.title,
          url: original.url,
          text: original.text,
          relevanceScore: score,
        ));
      }
      return reranked;
    } finally {
      client.close();
    }
  }

  List<RerankedChunk> _rerankLocal(
    String query,
    List<RerankedChunk> chunks,
    int topK,
  ) {
    final queryTokens = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2)
        .toSet();

    final scored = chunks.map((chunk) {
      final textLower = chunk.text.toLowerCase();
      final titleLower = chunk.title.toLowerCase();

      double score = 0.0;

      // Exact phrase match bonus
      if (textLower.contains(query.toLowerCase())) {
        score += 0.4;
      }

      // Title match bonus
      for (final token in queryTokens) {
        if (titleLower.contains(token)) {
          score += 0.15;
        }
      }

      // Token overlap and frequency
      int matchCount = 0;
      for (final token in queryTokens) {
        final occurrences = RegExp.escape(token).allMatches(textLower).length;
        if (occurrences > 0) {
          matchCount++;
          score += min(0.3, occurrences * 0.05);
        }
      }

      if (queryTokens.isNotEmpty) {
        score += (matchCount / queryTokens.length) * 0.3;
      }

      final normalizedScore = min(0.99, max(0.01, score));

      return RerankedChunk(
        sourceIndex: chunk.sourceIndex,
        title: chunk.title,
        url: chunk.url,
        text: chunk.text,
        relevanceScore: normalizedScore,
      );
    }).toList();

    scored.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return scored.take(topK).toList();
  }
}
