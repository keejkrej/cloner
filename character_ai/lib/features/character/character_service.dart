import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../core/db/database_service.dart';
import '../../core/settings/settings_service.dart';
import '../../core/voice/voice_service.dart';
import 'models.dart';

class CharacterService extends ChangeNotifier {
  final SettingsService settingsService;
  late final VoiceService voiceService;
  final _uuid = const Uuid();

  List<Character> _characters = [];
  Character? _currentCharacter;
  List<ChatMessage> _messages = [];
  List<CharacterMemory> _memories = [];

  bool _isGenerating = false;

  CharacterService({required this.settingsService}) {
    voiceService = VoiceService(settingsService: settingsService);
  }

  List<Character> get characters => List.unmodifiable(_characters);
  Character? get currentCharacter => _currentCharacter;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<CharacterMemory> get memories => List.unmodifiable(_memories);
  bool get isGenerating => _isGenerating;

  @override
  void dispose() {
    voiceService.dispose();
    super.dispose();
  }

  Future<void> init() async {
    await _seedDefaultCharactersIfNeeded();
    await loadCharacters();
    if (_characters.isNotEmpty) {
      await selectCharacter(_characters.first.id);
    }
  }

  Future<void> _seedDefaultCharactersIfNeeded() async {
    final db = await DatabaseService.database;
    final countRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM characters');
    final count = countRes.isNotEmpty ? countRes.first['cnt'] as int? : 0;
    if (count == null || count == 0) {
      final defaults = [
        Character(
          id: 'sherlock',
          name: 'Sherlock Holmes',
          avatar: '🕵️',
          personality: 'Brilliant, observant, intensely analytical, polite yet impatient with dullness.',
          speakingStyle: 'Formal Victorian English, razor-sharp deductions, references Baker Street and observation.',
          greeting: 'Ah, capital! Come in and take a seat. I was just cataloging tobacco ash. What mystery brings you to Baker Street?',
          voice: 'onyx',
          createdAt: DateTime.now(),
        ),
        Character(
          id: 'socrates',
          name: 'Socrates',
          avatar: '🏛️',
          personality: 'Humble seeker of truth, relentless questioner, ironist, lover of wisdom and virtue.',
          speakingStyle: 'Probing Socratic dialogues, philosophical metaphors, questioning underlying assumptions.',
          greeting: 'Greetings my friend. I know only that I know nothing. Shall we examine what it means to live a good life?',
          voice: 'echo',
          createdAt: DateTime.now(),
        ),
        Character(
          id: 'cyberpunk',
          name: 'Vex (Netrunner)',
          avatar: '⚡',
          personality: 'Cynical, street-smart hacker from Neo-Tokyo, fast-talking, rebellious.',
          speakingStyle: 'Cyberpunk slang (choom, ICE, deck, chrome), edgy, fast and pragmatic.',
          greeting: 'Jack in or get out of my frequency, choom. ICE is melting and corporate drones are scanning the node. What\'s the payload?',
          voice: 'nova',
          createdAt: DateTime.now(),
        ),
        Character(
          id: 'yoda',
          name: 'Master Yoda',
          avatar: '🧙‍♂️',
          personality: 'Ancient Jedi Master, wise, serene, playful yet disciplined.',
          speakingStyle: 'Object-Subject-Verb inverted syntax, speaks of the Force, luminous beings, and patience.',
          greeting: 'Patience you must have, young one. Sense your thoughts, I do. Seek guidance in the Force, do you?',
          voice: 'fable',
          createdAt: DateTime.now(),
        ),
      ];

      for (final char in defaults) {
        await db.insert('characters', char.toMap());
        // Insert greeting as initial message
        final greetingMsg = ChatMessage(
          id: _uuid.v4(),
          characterId: char.id,
          role: 'assistant',
          content: char.greeting,
          audioPath: null,
          createdAt: DateTime.now(),
        );
        await db.insert('messages', greetingMsg.toMap());
      }
    }
  }

  Future<void> loadCharacters() async {
    final db = await DatabaseService.database;
    final rows = await db.query('characters', orderBy: 'created_at ASC');
    _characters = rows.map((r) => Character.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> selectCharacter(String id) async {
    final db = await DatabaseService.database;
    final charRows = await db.query('characters', where: 'id = ?', whereArgs: [id]);
    if (charRows.isEmpty) return;

    _currentCharacter = Character.fromMap(charRows.first);

    // Load messages
    final msgRows = await db.query('messages', where: 'character_id = ?', whereArgs: [id], orderBy: 'created_at ASC');
    _messages = msgRows.map((m) => ChatMessage.fromMap(m)).toList();

    // Load character memories
    await _loadMemoriesForCharacter(id);

    notifyListeners();
  }

  Future<void> _loadMemoriesForCharacter(String characterId) async {
    final db = await DatabaseService.database;
    final memRows = await db.query('character_memories', where: 'character_id = ?', whereArgs: [characterId], orderBy: 'created_at DESC');
    _memories = memRows.map((r) => CharacterMemory.fromMap(r)).toList();
  }

  Future<void> createCharacter({
    required String name,
    required String avatar,
    required String personality,
    required String speakingStyle,
    required String greeting,
    required String voice,
  }) async {
    final char = Character(
      id: _uuid.v4(),
      name: name.trim(),
      avatar: avatar.trim().isEmpty ? '🎭' : avatar.trim(),
      personality: personality.trim(),
      speakingStyle: speakingStyle.trim(),
      greeting: greeting.trim(),
      voice: voice,
      createdAt: DateTime.now(),
    );

    final db = await DatabaseService.database;
    await db.insert('characters', char.toMap());

    final greetingMsg = ChatMessage(
      id: _uuid.v4(),
      characterId: char.id,
      role: 'assistant',
      content: char.greeting,
      audioPath: null,
      createdAt: DateTime.now(),
    );
    await db.insert('messages', greetingMsg.toMap());

    _characters.add(char);
    await selectCharacter(char.id);
  }

  Future<void> deleteMemory(String memoryId) async {
    final db = await DatabaseService.database;
    await db.delete('character_memories', where: 'id = ?', whereArgs: [memoryId]);
    _memories.removeWhere((m) => m.id == memoryId);
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isGenerating || _currentCharacter == null) return;

    final char = _currentCharacter!;
    final db = await DatabaseService.database;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      characterId: char.id,
      role: 'user',
      content: cleanText,
      audioPath: null,
      createdAt: DateTime.now(),
    );
    _messages.add(userMsg);
    await db.insert('messages', userMsg.toMap());
    notifyListeners();

    _isGenerating = true;
    notifyListeners();

    // Build memory context
    final memoryBuffer = StringBuffer();
    if (_memories.isNotEmpty) {
      memoryBuffer.writeln('\n[What you personally remember about the user from past conversations]:');
      for (final m in _memories) {
        memoryBuffer.writeln('- ${m.fact}');
      }
      memoryBuffer.writeln('Naturally use these remembered details in character without breaking persona.');
    }

    final systemPrompt = '''You are ${char.name}.
Persona & Traits: ${char.personality}
Speaking Style & Tone: ${char.speakingStyle}

Rules:
1. Stay 100% in persona. Never break character. Never mention you are an AI or language model.
2. React emotionally and intellectually according to your character traits.
3. Keep replies engaging, vivid, and conversational.
${memoryBuffer.toString()}''';

    final client = http.Client();
    String assistantReply = '';

    try {
      var baseUrl = settingsService.llmBaseUrl.trim();
      if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);

      final response = await client.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settingsService.llmApiKey}',
        },
        body: jsonEncode({
          'model': settingsService.llmModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            ..._messages.map((m) => {'role': m.role, 'content': m.content}),
          ],
          'temperature': 0.85,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        assistantReply = json['choices']?[0]?['message']?['content'] as String? ?? '';
      } else {
        assistantReply = '*(A sudden static interruption...)*';
      }
    } catch (e) {
      assistantReply = '*(Trouble connecting to ${char.name}...)*';
    } finally {
      client.close();
    }

    // Voice synthesis if voice key available
    String? audioPath;
    if (assistantReply.isNotEmpty) {
      try {
        audioPath = await voiceService.synthesizeSpeech(
          text: assistantReply,
          voice: char.voice,
          characterId: char.id,
        );
        if (audioPath != null && settingsService.autoPlayVoice) {
          await voiceService.playAudio(audioPath);
        }
      } catch (_) {}
    }

    final assistantMsg = ChatMessage(
      id: _uuid.v4(),
      characterId: char.id,
      role: 'assistant',
      content: assistantReply,
      audioPath: audioPath,
      createdAt: DateTime.now(),
    );
    _messages.add(assistantMsg);
    await db.insert('messages', assistantMsg.toMap());

    _isGenerating = false;
    notifyListeners();

    // Background Long-Term Memory Extraction
    _extractCharacterMemory(userText: cleanText, replyText: assistantReply, characterId: char.id);
  }

  Future<void> _extractCharacterMemory({
    required String userText,
    required String replyText,
    required String characterId,
  }) async {
    if (userText.length < 5 || !settingsService.hasValidApiKey) return;

    final client = http.Client();
    try {
      var baseUrl = settingsService.llmBaseUrl.trim();
      if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);

      final response = await client.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settingsService.llmApiKey}',
        },
        body: jsonEncode({
          'model': settingsService.llmModel,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a memory extractor. Analyze the user statement and identify any durable facts about the user (e.g. user\'s name, profession, tastes, hobbies, opinions). Output each fact as a bullet starting with "- ". If no durable user facts were revealed, output "NONE".',
            },
            {'role': 'user', 'content': 'User said: "$userText"\nCharacter replied: "$replyText"'},
          ],
          'temperature': 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final raw = json['choices']?[0]?['message']?['content'] as String? ?? '';
        final lines = raw.trim().split('\n');

        final db = await DatabaseService.database;
        for (final line in lines) {
          var cleanLine = line.trim();
          if (cleanLine.startsWith('-') || cleanLine.startsWith('*')) cleanLine = cleanLine.substring(1).trim();
          if (cleanLine.isEmpty || cleanLine.toUpperCase() == 'NONE') continue;

          final alreadyExists = _memories.any((m) => m.fact.toLowerCase() == cleanLine.toLowerCase());
          if (!alreadyExists) {
            final newMem = CharacterMemory(
              id: _uuid.v4(),
              characterId: characterId,
              fact: cleanLine,
              createdAt: DateTime.now(),
            );
            await db.insert('character_memories', newMem.toMap());
            _memories.insert(0, newMem);
            notifyListeners();
          }
        }
      }
    } catch (_) {} finally {
      client.close();
    }
  }
}
