import 'package:flutter_test/flutter_test.dart';
import 'package:chatgpt/features/chat/models.dart';
import 'package:chatgpt/features/memory/memory_service.dart';

void main() {
  test('Conversation and Message models serialization', () {
    final now = DateTime.now();
    final conv = Conversation(
      id: 'test-conv-1',
      title: 'Test Title',
      createdAt: now,
      updatedAt: now,
    );

    final map = conv.toMap();
    final restored = Conversation.fromMap(map);
    expect(restored.id, 'test-conv-1');
    expect(restored.title, 'Test Title');

    final msg = Message(
      id: 'msg-1',
      conversationId: 'test-conv-1',
      role: 'user',
      content: 'Hello, testing memory',
      createdAt: now,
    );
    final msgMap = msg.toMap();
    final restoredMsg = Message.fromMap(msgMap);
    expect(restoredMsg.content, 'Hello, testing memory');
    expect(restoredMsg.role, 'user');
  });

  test('Memory item system prompt formatting', () {
    final memoryService = MemoryService();
    // initially empty
    expect(memoryService.buildMemorySystemPrompt(), '');
  });
}
