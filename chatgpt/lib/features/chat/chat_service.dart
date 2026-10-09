import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/database_service.dart';
import '../../core/llm/llm_client.dart';
import '../../core/settings/settings_service.dart';
import '../memory/memory_service.dart';
import 'models.dart';

class ChatService extends ChangeNotifier {
  final SettingsService settingsService;
  final MemoryService memoryService;
  final _uuid = const Uuid();

  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  List<Message> _messages = [];
  bool _isStreaming = false;
  http.Client? _activeStreamingClient;
  StreamSubscription<String>? _activeStreamSub;

  ChatService({
    required this.settingsService,
    required this.memoryService,
  });

  List<Conversation> get conversations => List.unmodifiable(_conversations);
  Conversation? get currentConversation => _currentConversation;
  List<Message> get messages => List.unmodifiable(_messages);
  bool get isStreaming => _isStreaming;

  Future<void> init() async {
    await loadConversations();
    if (_conversations.isNotEmpty) {
      await selectConversation(_conversations.first.id);
    } else {
      await startNewConversation();
    }
  }

  Future<void> loadConversations() async {
    final db = await DatabaseService.database;
    final results = await db.query(
      'conversations',
      orderBy: 'updated_at DESC',
    );
    _conversations = results.map((c) => Conversation.fromMap(c)).toList();
    notifyListeners();
  }

  Future<void> selectConversation(String id) async {
    if (_isStreaming) {
      stopStreaming();
    }

    final db = await DatabaseService.database;
    final convRows = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (convRows.isEmpty) return;

    _currentConversation = Conversation.fromMap(convRows.first);

    final msgRows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [id],
      orderBy: 'created_at ASC',
    );
    _messages = msgRows.map((m) => Message.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> startNewConversation() async {
    if (_isStreaming) {
      stopStreaming();
    }

    final newConv = Conversation(
      id: _uuid.v4(),
      title: 'New Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final db = await DatabaseService.database;
    await db.insert('conversations', newConv.toMap());

    _conversations.insert(0, newConv);
    _currentConversation = newConv;
    _messages = [];
    notifyListeners();
  }

  Future<void> deleteConversation(String id) async {
    if (_currentConversation?.id == id && _isStreaming) {
      stopStreaming();
    }

    final db = await DatabaseService.database;
    await db.delete('messages', where: 'conversation_id = ?', whereArgs: [id]);
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);

    _conversations.removeWhere((c) => c.id == id);

    if (_currentConversation?.id == id) {
      if (_conversations.isNotEmpty) {
        await selectConversation(_conversations.first.id);
      } else {
        await startNewConversation();
      }
    } else {
      notifyListeners();
    }
  }

  void stopStreaming() {
    if (!_isStreaming) return;
    _activeStreamSub?.cancel();
    _activeStreamSub = null;
    _activeStreamingClient?.close();
    _activeStreamingClient = null;
    _isStreaming = false;

    // Save whatever partial message we received so far
    if (_messages.isNotEmpty && _messages.last.role == 'assistant') {
      _saveMessageToDb(_messages.last);
    }

    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isStreaming) return;

    if (_currentConversation == null) {
      await startNewConversation();
    }

    final conv = _currentConversation!;
    final db = await DatabaseService.database;

    // Create and record user message
    final userMessage = Message(
      id: _uuid.v4(),
      conversationId: conv.id,
      role: 'user',
      content: cleanText,
      createdAt: DateTime.now(),
    );

    _messages.add(userMessage);
    await _saveMessageToDb(userMessage);

    // Auto-update conversation title if it's the first message
    if (_messages.length == 1 || conv.title == 'New Chat') {
      final newTitle = cleanText.length > 32
          ? '${cleanText.substring(0, 32)}...'
          : cleanText;
      final updatedConv = Conversation(
        id: conv.id,
        title: newTitle,
        createdAt: conv.createdAt,
        updatedAt: DateTime.now(),
      );
      _currentConversation = updatedConv;
      final idx = _conversations.indexWhere((c) => c.id == conv.id);
      if (idx != -1) {
        _conversations[idx] = updatedConv;
      }
      await db.update(
        'conversations',
        updatedConv.toMap(),
        where: 'id = ?',
        whereArgs: [conv.id],
      );
    } else {
      await db.update(
        'conversations',
        {'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [conv.id],
      );
    }

    notifyListeners();

    // Prepare assistant response placeholder
    final assistantMsgId = _uuid.v4();
    var assistantMessage = Message(
      id: assistantMsgId,
      conversationId: conv.id,
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
    );
    _messages.add(assistantMessage);
    _isStreaming = true;
    notifyListeners();

    // Build context
    final memoryPrompt = settingsService.memoryEnabled
        ? memoryService.buildMemorySystemPrompt()
        : '';

    final systemInstruction = '''You are a helpful, thoughtful, and precise AI assistant.
$memoryPrompt''';

    final payloadMessages = <ChatMessagePayload>[
      ChatMessagePayload(role: 'system', content: systemInstruction),
      ..._messages.sublist(0, _messages.length - 1).map(
            (m) => ChatMessagePayload(role: m.role, content: m.content),
          ),
    ];

    final client = LlmClient(
      baseUrl: settingsService.baseUrl,
      apiKey: settingsService.apiKey,
    );

    _activeStreamingClient = http.Client();
    final stringBuffer = StringBuffer();

    try {
      final stream = client.streamChatCompletion(
        model: settingsService.model,
        messages: payloadMessages,
        clientOverride: _activeStreamingClient,
      );

      final completer = Completer<void>();
      _activeStreamSub = stream.listen(
        (chunk) {
          stringBuffer.write(chunk);
          final updatedMsg = assistantMessage.copyWith(content: stringBuffer.toString());
          _messages[_messages.length - 1] = updatedMsg;
          notifyListeners();
        },
        onError: (err) {
          if (!_isStreaming) return; // user stopped intentionally
          stringBuffer.write('\n\n**Error during streaming:** $err');
          final updatedMsg = assistantMessage.copyWith(content: stringBuffer.toString());
          _messages[_messages.length - 1] = updatedMsg;
          if (!completer.isCompleted) completer.complete();
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );

      await completer.future;
    } catch (e) {
      if (_isStreaming) {
        stringBuffer.write('\n\n**Error:** $e');
        final updatedMsg = assistantMessage.copyWith(content: stringBuffer.toString());
        _messages[_messages.length - 1] = updatedMsg;
      }
    } finally {
      _isStreaming = false;
      _activeStreamSub = null;
      _activeStreamingClient?.close();
      _activeStreamingClient = null;

      final finalAssistantMsg = _messages.last;
      await _saveMessageToDb(finalAssistantMsg);
      notifyListeners();

      // Trigger background memory extraction if enabled
      if (settingsService.memoryEnabled && finalAssistantMsg.content.isNotEmpty) {
        memoryService.extractAndSaveMemories(
          client: client,
          extractionModel: settingsService.extractionModel,
          userMessage: cleanText,
          assistantResponse: finalAssistantMsg.content,
          conversationId: conv.id,
        );
      }
    }
  }

  Future<void> _saveMessageToDb(Message message) async {
    final db = await DatabaseService.database;
    await db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
