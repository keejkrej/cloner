import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatMessagePayload {
  final String role;
  final String content;

  ChatMessagePayload({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class LlmClient {
  final String baseUrl;
  final String apiKey;

  LlmClient({required this.baseUrl, required this.apiKey});

  String _cleanBaseUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// Sends a streaming chat completion request and yields chunk tokens.
  /// If [cancelToken] is called or the stream subscription is cancelled, request closes.
  Stream<String> streamChatCompletion({
    required String model,
    required List<ChatMessagePayload> messages,
    double temperature = 0.7,
    http.Client? clientOverride,
  }) async* {
    final client = clientOverride ?? http.Client();
    final url = Uri.parse('${_cleanBaseUrl(baseUrl)}/chat/completions');

    final request = http.Request('POST', url);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
    });

    final body = jsonEncode({
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': true,
      'temperature': temperature,
    });
    request.body = body;

    http.StreamedResponse response;
    try {
      response = await client.send(request);
    } catch (e) {
      if (clientOverride == null) client.close();
      throw Exception('Failed to connect to LLM API: $e');
    }

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      if (clientOverride == null) client.close();
      throw Exception('API returned error (${response.statusCode}): $errorBody');
    }

    try {
      final lineStream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final rawLine in lineStream) {
        final line = rawLine.trim();
        if (line.isEmpty) continue;
        if (!line.startsWith('data:')) continue;

        final data = line.substring(5).trim();
        if (data == '[DONE]') {
          break;
        }

        try {
          final json = jsonDecode(data);
          final choices = json['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          }
        } catch (_) {
          // Skip malformed SSE chunks
        }
      }
    } finally {
      if (clientOverride == null) {
        client.close();
      }
    }
  }

  /// Sends a non-streaming chat completion request (used for fact extraction)
  Future<String> completeChat({
    required String model,
    required List<ChatMessagePayload> messages,
    double temperature = 0.0,
  }) async {
    final client = http.Client();
    try {
      final url = Uri.parse('${_cleanBaseUrl(baseUrl)}/chat/completions');
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages.map((m) => m.toJson()).toList(),
          'stream': false,
          'temperature': temperature,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Extraction API failed (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body);
      final choices = json['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>?;
        return (message?['content'] as String?)?.trim() ?? '';
      }
      return '';
    } finally {
      client.close();
    }
  }
}
