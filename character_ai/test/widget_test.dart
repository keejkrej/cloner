import 'package:flutter_test/flutter_test.dart';
import 'package:character_ai/features/character/models.dart';

void main() {
  test('Character and ChatMessage model serialization', () {
    final now = DateTime.now();
    final character = Character(
      id: 'char-1',
      name: 'Sherlock Holmes',
      avatar: '🕵️',
      personality: 'Observant and analytical',
      speakingStyle: 'Victorian English',
      greeting: 'Elementary!',
      voice: 'onyx',
      createdAt: now,
    );

    final map = character.toMap();
    final restored = Character.fromMap(map);
    expect(restored.id, 'char-1');
    expect(restored.name, 'Sherlock Holmes');
    expect(restored.voice, 'onyx');

    final msg = ChatMessage(
      id: 'msg-1',
      characterId: 'char-1',
      role: 'user',
      content: 'Where were you last night?',
      audioPath: null,
      createdAt: now,
    );
    final msgMap = msg.toMap();
    final restoredMsg = ChatMessage.fromMap(msgMap);
    expect(restoredMsg.content, 'Where were you last night?');
  });

  test('CharacterMemory model serialization', () {
    final now = DateTime.now();
    final mem = CharacterMemory(
      id: 'mem-1',
      characterId: 'char-1',
      fact: 'User plays the violin',
      createdAt: now,
    );

    final map = mem.toMap();
    final restored = CharacterMemory.fromMap(map);
    expect(restored.fact, 'User plays the violin');
  });
}
