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

  Stream<String> streamChatCompletion({
    required String model,
    required List<ChatMessagePayload> messages,
    double temperature = 0.3,
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
      throw Exception('Failed to connect to LLM: $e');
    }

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      if (clientOverride == null) client.close();
      throw Exception('LLM error (${response.statusCode}): $errorBody');
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
        if (data == '[DONE]') break;

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
        } catch (_) {}
      }
    } finally {
      if (clientOverride == null) client.close();
    }
  }
}
