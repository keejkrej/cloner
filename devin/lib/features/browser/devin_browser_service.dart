import 'dart:async';
import 'package:http/http.dart' as http;

class BrowserState {
  final String currentUrl;
  final String title;
  final String content;
  final int statusCode;
  final bool isLoading;
  final List<String> history;

  BrowserState({
    this.currentUrl = 'about:blank',
    this.title = 'New Tab',
    this.content = '',
    this.statusCode = 200,
    this.isLoading = false,
    this.history = const [],
  });

  BrowserState copyWith({
    String? currentUrl,
    String? title,
    String? content,
    int? statusCode,
    bool? isLoading,
    List<String>? history,
  }) {
    return BrowserState(
      currentUrl: currentUrl ?? this.currentUrl,
      title: title ?? this.title,
      content: content ?? this.content,
      statusCode: statusCode ?? this.statusCode,
      isLoading: isLoading ?? this.isLoading,
      history: history ?? this.history,
    );
  }
}

class DevinBrowserService {
  final http.Client? client;
  final _stateController = StreamController<BrowserState>.broadcast();
  Stream<BrowserState> get onBrowserUpdated => _stateController.stream;

  BrowserState _state = BrowserState();
  BrowserState get state => _state;

  DevinBrowserService({this.client});

  Future<String> openAndRead(String url) async {
    var targetUrl = url.trim();
    if (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://')) {
      targetUrl = 'https://$targetUrl';
    }

    _state = _state.copyWith(
      currentUrl: targetUrl,
      isLoading: true,
      history: [..._state.history, targetUrl],
    );
    _stateController.add(_state);

    final httpClient = client ?? http.Client();
    try {
      final res = await httpClient.get(
        Uri.parse(targetUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Devin-Autonomous-Browser/1.0',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 15));

      final rawBody = res.body;
      final cleanText = _extractReadableContent(rawBody, targetUrl);

      _state = _state.copyWith(
        title: _extractTitle(rawBody, targetUrl),
        content: cleanText,
        statusCode: res.statusCode,
        isLoading: false,
      );
      _stateController.add(_state);

      return cleanText;
    } catch (e) {
      final errorText = 'Browser navigation error for $targetUrl: $e';
      _state = _state.copyWith(
        title: 'Error loading page',
        content: errorText,
        statusCode: 500,
        isLoading: false,
      );
      _stateController.add(_state);
      return errorText;
    }
  }

  String _extractTitle(String html, String fallback) {
    final titleMatch = RegExp(r'<title>(.*?)</title>', caseSensitive: false, dotAll: true).firstMatch(html);
    if (titleMatch != null) {
      return titleMatch.group(1)!.trim();
    }
    return fallback;
  }

  String _extractReadableContent(String html, String url) {
    if (!html.contains('<html') && !html.contains('<body')) {
      return html;
    }

    // Strip scripts and styles
    var text = html
        .replaceAll(RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>', caseSensitive: false), '');

    // Convert common tags to markdown
    text = text
        .replaceAll(RegExp(r'<h1\b[^>]*>(.*?)<\/h1>', caseSensitive: false), '\n# \$1\n')
        .replaceAll(RegExp(r'<h2\b[^>]*>(.*?)<\/h2>', caseSensitive: false), '\n## \$1\n')
        .replaceAll(RegExp(r'<h3\b[^>]*>(.*?)<\/h3>', caseSensitive: false), '\n### \$1\n')
        .replaceAll(RegExp(r'<p\b[^>]*>(.*?)<\/p>', caseSensitive: false), '\n\$1\n')
        .replaceAll(RegExp(r'<li\b[^>]*>(.*?)<\/li>', caseSensitive: false), '\n- \$1')
        .replaceAll(RegExp(r'<br\s*[\/]?>', caseSensitive: false), '\n');

    // Strip remaining tags
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
    // Clean multiple whitespace
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');

    return text.trim();
  }

  void dispose() {
    _stateController.close();
  }
}
