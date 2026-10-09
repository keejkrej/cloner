import 'package:flutter_test/flutter_test.dart';
import 'package:elevenlabs/features/tts/text_chunker.dart';
import 'package:elevenlabs/features/voices/models/voice.dart';
import 'package:elevenlabs/features/history/models/generation.dart';

void main() {
  group('TextChunker Tests', () {
    test('Short text produces a single chunk', () {
      const text = 'Hello world, this is a short test sentence.';
      final chunks = TextChunker.chunkText(text, maxChunkLength: 200);
      expect(chunks.length, equals(1));
      expect(chunks.first, equals(text));
    });

    test('Long text is split into chunks respecting sentence boundaries', () {
      final text = 'Sentence number one. ' * 20;
      final chunks = TextChunker.chunkText(text, maxChunkLength: 100);
      expect(chunks.length, greaterThan(1));
      for (final chunk in chunks) {
        expect(chunk.length, lessThanOrEqualTo(120));
      }
    });

    test('Paragraphs are respected and preserved', () {
      const text = 'First paragraph text.\n\nSecond paragraph text.\n\nThird paragraph text.';
      final chunks = TextChunker.chunkText(text, maxChunkLength: 30);
      expect(chunks.length, equals(3));
      expect(chunks[0], equals('First paragraph text.'));
      expect(chunks[1], equals('Second paragraph text.'));
      expect(chunks[2], equals('Third paragraph text.'));
    });
  });

  group('Models Serialization Tests', () {
    test('Voice model toMap and fromMap', () {
      const voice = Voice(
        id: 'voice_123',
        name: 'Jordan',
        category: 'cloned',
        description: 'Test cloned voice',
        samplePath: '/path/to/sample.wav',
        createdAt: 123456789,
      );

      final map = voice.toMap();
      final fromMap = Voice.fromMap(map);

      expect(fromMap.id, equals(voice.id));
      expect(fromMap.name, equals(voice.name));
      expect(fromMap.category, equals('cloned'));
      expect(fromMap.isCloned, isTrue);
      expect(fromMap.samplePath, equals('/path/to/sample.wav'));
    });

    test('Generation model toMap and fromMap', () {
      const gen = Generation(
        id: 'gen_123',
        voiceId: 'voice_123',
        voiceName: 'Jordan',
        fullText: 'Synthesized text message',
        audioPath: '/path/to/gen.mp3',
        characterCount: 24,
        createdAt: 987654321,
      );

      final map = gen.toMap();
      final fromMap = Generation.fromMap(map);

      expect(fromMap.id, equals(gen.id));
      expect(fromMap.voiceName, equals(gen.voiceName));
      expect(fromMap.characterCount, equals(24));
    });
  });
}
