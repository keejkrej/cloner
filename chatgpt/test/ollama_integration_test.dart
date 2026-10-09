import 'package:flutter_test/flutter_test.dart';
import 'package:chatgpt/core/llm/llm_client.dart';

void main() {
  const baseUrl = 'http://127.0.0.1:11434/v1';
  const apiKey = '48188830f96246f7a15fdd4c168afb3c.iuWcpdWxke5JJMeQkZyes7rt';
  const model = 'glm-5.3-flash:cloud';

  test('Ollama streaming chat completion works end-to-end', () async {
    final client = LlmClient(baseUrl: baseUrl, apiKey: apiKey);
    final messages = [
      ChatMessagePayload(role: 'user', content: 'Say "Antigravity works!" in exactly three words.'),
    ];

    final chunks = <String>[];
    await for (final token in client.streamChatCompletion(model: model, messages: messages)) {
      chunks.add(token);
    }

    final fullResponse = chunks.join();
    print('Streamed response: "$fullResponse" (${chunks.length} tokens)');
    expect(fullResponse.isNotEmpty, isTrue);
    expect(chunks.length, greaterThan(0));
  });

  test('Ollama non-streaming extraction works for memory', () async {
    final client = LlmClient(baseUrl: baseUrl, apiKey: apiKey);
    final extractionPrompt = '''
You are a memory extraction assistant. Analyze the conversation turn and extract key facts about the user (preferences, background, name, interests).
Return only one concise fact per line. If there are no durable facts to remember, respond with "NONE".

User: My favorite programming language is Dart and I love Flutter.
Assistant: That is wonderful! Flutter and Dart make a great combo.
''';

    final result = await client.completeChat(
      model: model,
      messages: [ChatMessagePayload(role: 'user', content: extractionPrompt)],
    );

    print('Extracted memory facts:\n$result');
    expect(result.isNotEmpty, isTrue);
    expect(result.toLowerCase().contains('dart') || result.toLowerCase().contains('flutter'), isTrue);
  });
}
