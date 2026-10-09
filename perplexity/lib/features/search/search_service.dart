import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'models.dart';

class SearchService {
  Future<List<RawSearchResult>> search({
    required String query,
    required String provider,
    required String apiKey,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    switch (provider.toLowerCase()) {
      case 'tavily':
        if (apiKey.isNotEmpty) {
          return await _searchTavily(cleanQuery, apiKey);
        }
        return await _searchDuckDuckGo(cleanQuery);

      case 'brave':
        if (apiKey.isNotEmpty) {
          return await _searchBrave(cleanQuery, apiKey);
        }
        return await _searchDuckDuckGo(cleanQuery);

      case 'serper':
        if (apiKey.isNotEmpty) {
          return await _searchSerper(cleanQuery, apiKey);
        }
        return await _searchDuckDuckGo(cleanQuery);

      case 'duckduckgo':
      default:
        return await _searchDuckDuckGo(cleanQuery);
    }
  }

  Future<List<RawSearchResult>> _searchTavily(String query, String apiKey) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('https://api.tavily.com/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_key': apiKey,
          'query': query,
          'search_depth': 'basic',
          'max_results': 8,
          'include_raw_content': false,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Tavily search failed (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body);
      final results = json['results'] as List<dynamic>? ?? [];
      return results.map((r) => RawSearchResult(
        title: r['title'] as String? ?? 'Untitled',
        url: r['url'] as String? ?? '',
        content: r['content'] as String? ?? '',
      )).where((r) => r.content.isNotEmpty).toList();
    } finally {
      client.close();
    }
  }

  Future<List<RawSearchResult>> _searchBrave(String query, String apiKey) async {
    final client = http.Client();
    try {
      final uri = Uri.parse('https://api.search.brave.com/res/v1/web/search').replace(queryParameters: {
        'q': query,
        'count': '8',
      });
      final response = await client.get(
        uri,
        headers: {
          'X-Subscription-Token': apiKey,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Brave search failed (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body);
      final web = json['web']?['results'] as List<dynamic>? ?? [];
      return web.map((r) => RawSearchResult(
        title: r['title'] as String? ?? 'Untitled',
        url: r['url'] as String? ?? '',
        content: r['description'] as String? ?? '',
      )).where((r) => r.content.isNotEmpty).toList();
    } finally {
      client.close();
    }
  }

  Future<List<RawSearchResult>> _searchSerper(String query, String apiKey) async {
    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('https://google.serper.dev/search'),
        headers: {
          'X-API-KEY': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'q': query,
          'num': 8,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Serper failed (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body);
      final organic = json['organic'] as List<dynamic>? ?? [];
      return organic.map((r) => RawSearchResult(
        title: r['title'] as String? ?? 'Untitled',
        url: r['link'] as String? ?? '',
        content: r['snippet'] as String? ?? '',
      )).where((r) => r.content.isNotEmpty).toList();
    } finally {
      client.close();
    }
  }

  Future<List<RawSearchResult>> _searchDuckDuckGo(String query) async {
    final client = http.Client();
    try {
      final uri = Uri.parse('https://html.duckduckgo.com/html/').replace(queryParameters: {'q': query});
      final response = await client.post(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'q=${Uri.encodeQueryComponent(query)}',
      );

      if (response.statusCode != 200) {
        return [];
      }

      final document = html_parser.parse(response.body);
      final results = <RawSearchResult>[];
      final elements = document.querySelectorAll('.result');

      for (final el in elements) {
        final titleEl = el.querySelector('.result__title a');
        final snippetEl = el.querySelector('.result__snippet');
        if (titleEl != null && snippetEl != null) {
          final title = titleEl.text.trim();
          var href = titleEl.attributes['href'] ?? '';
          if (href.contains('uddg=')) {
            final uriPart = Uri.parse(href);
            final actualUrl = uriPart.queryParameters['uddg'];
            if (actualUrl != null) href = Uri.decodeFull(actualUrl);
          }
          final snippet = snippetEl.text.trim();
          if (snippet.isNotEmpty && href.startsWith('http')) {
            results.add(RawSearchResult(title: title, url: href, content: snippet));
          }
        }
        if (results.length >= 8) break;
      }

      return results;
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }
}
