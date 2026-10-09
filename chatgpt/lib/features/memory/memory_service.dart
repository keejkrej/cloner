import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/database_service.dart';
import '../../core/llm/llm_client.dart';
import '../chat/models.dart';

class MemoryService extends ChangeNotifier {
  final _uuid = const Uuid();
  List<MemoryItem> _memories = [];

  List<MemoryItem> get memories => List.unmodifiable(_memories);

  Future<void> loadMemories() async {
    final db = await DatabaseService.database;
    final results = await db.query(
      'memories',
      orderBy: 'created_at DESC',
    );
    _memories = results.map((m) => MemoryItem.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> deleteMemory(String id) async {
    final db = await DatabaseService.database;
    await db.delete('memories', where: 'id = ?', whereArgs: [id]);
    _memories.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  Future<void> addManualMemory(String fact) async {
    final cleanFact = fact.trim();
    if (cleanFact.isEmpty) return;

    final db = await DatabaseService.database;
    final memory = MemoryItem(
      id: _uuid.v4(),
      fact: cleanFact,
      sourceConversationId: null,
      createdAt: DateTime.now(),
    );
    await db.insert('memories', memory.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    _memories.insert(0, memory);
    notifyListeners();
  }

  /// Builds the system prompt snippet containing remembered user facts
  String buildMemorySystemPrompt() {
    if (_memories.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('\n[User Profile & Persistent Memory]');
    buffer.writeln('The following facts are remembered across conversations about the user:');
    for (final mem in _memories) {
      buffer.writeln('- ${mem.fact}');
    }
    buffer.writeln('Incorporate this context naturally whenever relevant.');
    return buffer.toString();
  }

  /// Uses a cheap LLM call to extract durable user facts after a turn
  Future<void> extractAndSaveMemories({
    required LlmClient client,
    required String extractionModel,
    required String userMessage,
    required String assistantResponse,
    String? conversationId,
  }) async {
    // Avoid running on short or empty turns
    if (userMessage.trim().length < 5) return;

    final systemInstruction = ChatMessagePayload(
      role: 'system',
      content: '''You are a background memory extraction system.
Analyze the user's message and extract any durable, permanent facts about the user (e.g. name, profession, location, preferences, family, personal projects, hobbies, habits, specific instructions for how they like answers formatted).

Rules:
1. ONLY extract lasting facts about the USER.
2. Ignore ephemeral queries, transient questions, greetings, or code requests.
3. Return each extracted fact as a single concise sentence on its own line starting with "- ".
4. If no durable user facts were revealed, output exactly "NONE".
''',
    );

    final turnContext = ChatMessagePayload(
      role: 'user',
      content: '''User said: "$userMessage"
Assistant replied: "$assistantResponse"

Extracted facts:''',
    );

    try {
      final rawResult = await client.completeChat(
        model: extractionModel,
        messages: [systemInstruction, turnContext],
        temperature: 0.0,
      );

      final trimmed = rawResult.trim();
      if (trimmed.isEmpty || trimmed.toUpperCase() == 'NONE') {
        return;
      }

      final lines = trimmed.split('\n');
      final db = await DatabaseService.database;
      bool hasNew = false;

      for (final line in lines) {
        var cleanLine = line.trim();
        if (cleanLine.startsWith('-') || cleanLine.startsWith('*')) {
          cleanLine = cleanLine.substring(1).trim();
        }
        if (cleanLine.isEmpty || cleanLine.toUpperCase() == 'NONE') continue;

        // Check if identical or near-identical fact already exists
        final alreadyExists = _memories.any(
          (m) => m.fact.toLowerCase() == cleanLine.toLowerCase(),
        );

        if (!alreadyExists) {
          final newMem = MemoryItem(
            id: _uuid.v4(),
            fact: cleanLine,
            sourceConversationId: conversationId,
            createdAt: DateTime.now(),
          );
          await db.insert('memories', newMem.toMap());
          _memories.insert(0, newMem);
          hasNew = true;
        }
      }

      if (hasNew) {
        notifyListeners();
      }
    } catch (e) {
      // Memory extraction failure should never crash the app or interrupt the chat
      debugPrint('Memory extraction error: $e');
    }
  }
}
