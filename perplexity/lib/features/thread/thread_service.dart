import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/database_service.dart';
import '../../core/llm/llm_client.dart';
import '../../core/settings/settings_service.dart';
import '../rerank/rerank_service.dart';
import '../search/models.dart';
import '../search/search_service.dart';

enum SearchStep {
  idle,
  searching,
  reranking,
  generating,
}

class ThreadService extends ChangeNotifier {
  final SettingsService settingsService;
  final SearchService searchService = SearchService();
  final RerankService rerankService = RerankService();
  final _uuid = const Uuid();

  List<SearchThread> _threads = [];
  SearchThread? _currentThread;
  List<ThreadMessage> _messages = [];
  List<SourceCard> _currentSources = [];

  SearchStep _currentStep = SearchStep.idle;
  String _statusText = '';
  bool _isStreaming = false;
  http.Client? _activeClient;
  StreamSubscription<String>? _activeSub;

  ThreadService({required this.settingsService});

  List<SearchThread> get threads => List.unmodifiable(_threads);
  SearchThread? get currentThread => _currentThread;
  List<ThreadMessage> get messages => List.unmodifiable(_messages);
  List<SourceCard> get currentSources => List.unmodifiable(_currentSources);
  SearchStep get currentStep => _currentStep;
  String get statusText => _statusText;
  bool get isStreaming => _isStreaming;

  Future<void> init() async {
    await loadThreads();
    if (_threads.isNotEmpty) {
      await selectThread(_threads.first.id);
    } else {
      await startNewThread();
    }
  }

  Future<void> loadThreads() async {
    final db = await DatabaseService.database;
    final rows = await db.query('threads', orderBy: 'updated_at DESC');
    _threads = rows.map((r) => SearchThread.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> selectThread(String id) async {
    if (_isStreaming) stopStreaming();

    final db = await DatabaseService.database;
    final threadRows = await db.query('threads', where: 'id = ?', whereArgs: [id]);
    if (threadRows.isEmpty) return;

    _currentThread = SearchThread.fromMap(threadRows.first);

    final msgRows = await db.query(
      'messages',
      where: 'thread_id = ?',
      whereArgs: [id],
      orderBy: 'created_at ASC',
    );
    _messages = msgRows.map((m) => ThreadMessage.fromMap(m)).toList();

    final srcRows = await db.query(
      'sources',
      where: 'thread_id = ?',
      whereArgs: [id],
      orderBy: 'index_num ASC',
    );
    _currentSources = srcRows.map((s) => SourceCard.fromMap(s)).toList();

    _currentStep = SearchStep.idle;
    _statusText = '';
    notifyListeners();
  }

  Future<void> startNewThread() async {
    if (_isStreaming) stopStreaming();

    final newThread = SearchThread(
      id: _uuid.v4(),
      title: 'New Search',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final db = await DatabaseService.database;
    await db.insert('threads', newThread.toMap());

    _threads.insert(0, newThread);
    _currentThread = newThread;
    _messages = [];
    _currentSources = [];
    _currentStep = SearchStep.idle;
    _statusText = '';
    notifyListeners();
  }

  Future<void> deleteThread(String id) async {
    if (_currentThread?.id == id && _isStreaming) stopStreaming();

    final db = await DatabaseService.database;
    await db.delete('sources', where: 'thread_id = ?', whereArgs: [id]);
    await db.delete('messages', where: 'thread_id = ?', whereArgs: [id]);
    await db.delete('threads', where: 'id = ?', whereArgs: [id]);

    _threads.removeWhere((t) => t.id == id);

    if (_currentThread?.id == id) {
      if (_threads.isNotEmpty) {
        await selectThread(_threads.first.id);
      } else {
        await startNewThread();
      }
    } else {
      notifyListeners();
    }
  }

  void stopStreaming() {
    if (!_isStreaming) return;
    _activeSub?.cancel();
    _activeSub = null;
    _activeClient?.close();
    _activeClient = null;
    _isStreaming = false;
    _currentStep = SearchStep.idle;
    _statusText = '';

    if (_messages.isNotEmpty && _messages.last.role == 'assistant') {
      _saveMessageToDb(_messages.last);
    }
    notifyListeners();
  }

  Future<void> submitQuery(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || _isStreaming) return;

    if (_currentThread == null) {
      await startNewThread();
    }

    final thread = _currentThread!;
    final db = await DatabaseService.database;

    // Record user message
    final userMessage = ThreadMessage(
      id: _uuid.v4(),
      threadId: thread.id,
      role: 'user',
      content: cleanQuery,
      createdAt: DateTime.now(),
    );
    _messages.add(userMessage);
    await _saveMessageToDb(userMessage);

    // Auto update thread title if first query
    if (_messages.length == 1 || thread.title == 'New Search') {
      final updatedTitle = cleanQuery.length > 36 ? '${cleanQuery.substring(0, 36)}...' : cleanQuery;
      final updatedThread = SearchThread(
        id: thread.id,
        title: updatedTitle,
        createdAt: thread.createdAt,
        updatedAt: DateTime.now(),
      );
      _currentThread = updatedThread;
      final idx = _threads.indexWhere((t) => t.id == thread.id);
      if (idx != -1) _threads[idx] = updatedThread;
      await db.update('threads', updatedThread.toMap(), where: 'id = ?', whereArgs: [thread.id]);
    } else {
      await db.update('threads', {'updated_at': DateTime.now().millisecondsSinceEpoch}, where: 'id = ?', whereArgs: [thread.id]);
    }

    // Step 1: Web Search
    _currentStep = SearchStep.searching;
    _statusText = 'Searching the web for "$cleanQuery"...';
    notifyListeners();

    List<RawSearchResult> rawResults = [];
    try {
      rawResults = await searchService.search(
        query: cleanQuery,
        provider: settingsService.searchProvider,
        apiKey: settingsService.searchApiKey,
      );
    } catch (e) {
      debugPrint('Search error: $e');
    }

    // Step 2: Rerank Results
    _currentStep = SearchStep.reranking;
    _statusText = 'Reranking ${rawResults.length} web sources for relevance...';
    notifyListeners();

    List<RerankedChunk> topChunks = [];
    try {
      topChunks = await rerankService.rerank(
        query: cleanQuery,
        rawResults: rawResults,
        provider: settingsService.rerankProvider,
        apiKey: settingsService.rerankApiKey,
        topK: 6,
      );
    } catch (e) {
      debugPrint('Rerank error: $e');
    }

    // Build unique source cards from topChunks
    final newSources = <SourceCard>[];
    int sourceIndex = 1;
    final seenUrls = <String>{};

    for (final chunk in topChunks) {
      if (!seenUrls.contains(chunk.url)) {
        seenUrls.add(chunk.url);
        newSources.add(SourceCard(
          id: _uuid.v4(),
          threadId: thread.id,
          indexNum: sourceIndex++,
          title: chunk.title,
          url: chunk.url,
          snippet: chunk.text,
          score: chunk.relevanceScore,
        ));
      }
    }

    _currentSources = newSources;
    // Persist sources
    await db.delete('sources', where: 'thread_id = ?', whereArgs: [thread.id]);
    for (final s in newSources) {
      await db.insert('sources', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Step 3: Stream Grounded Answer with Citations
    _currentStep = SearchStep.generating;
    _statusText = 'Synthesizing cited answer...';
    _isStreaming = true;

    final assistantMsg = ThreadMessage(
      id: _uuid.v4(),
      threadId: thread.id,
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
    );
    _messages.add(assistantMsg);
    notifyListeners();

    // Prepare context with numbered sources
    final sourcesContextBuffer = StringBuffer();
    sourcesContextBuffer.writeln('Web Sources:');
    for (int i = 0; i < newSources.length; i++) {
      final s = newSources[i];
      sourcesContextBuffer.writeln('Source [${s.indexNum}]:');
      sourcesContextBuffer.writeln('Title: ${s.title}');
      sourcesContextBuffer.writeln('URL: ${s.url}');
      sourcesContextBuffer.writeln('Content: ${s.snippet}\n');
    }

    final systemPrompt = '''You are Perplexity, an AI answer engine.
Your mission is to provide comprehensive, accurate, and direct answers grounded in real-time web search results.

Instructions:
1. Base your answer EXCLUSIVELY on the provided Web Sources.
2. In-line citations: ALWAYS place citations like [1] or [2][3] immediately after the relevant sentence or statement.
3. Every factual assertion must be attributed to its source number.
4. Format your answer with clean Markdown headings, bullet points, and paragraphs.
5. If the sources do not contain enough info, acknowledge it honestly.

${sourcesContextBuffer.toString()}''';

    final payloadMessages = <ChatMessagePayload>[
      ChatMessagePayload(role: 'system', content: systemPrompt),
      ..._messages.sublist(0, _messages.length - 1).map(
            (m) => ChatMessagePayload(role: m.role, content: m.content),
          ),
    ];

    final client = LlmClient(
      baseUrl: settingsService.llmBaseUrl,
      apiKey: settingsService.llmApiKey,
    );

    _activeClient = http.Client();
    final answerBuffer = StringBuffer();

    try {
      final stream = client.streamChatCompletion(
        model: settingsService.llmModel,
        messages: payloadMessages,
        clientOverride: _activeClient,
      );

      final completer = Completer<void>();
      _activeSub = stream.listen(
        (chunk) {
          answerBuffer.write(chunk);
          final updated = assistantMsg.copyWith(content: answerBuffer.toString());
          _messages[_messages.length - 1] = updated;
          notifyListeners();
        },
        onError: (err) {
          if (!_isStreaming) return;
          answerBuffer.write('\n\n**Error:** $err');
          final updated = assistantMsg.copyWith(content: answerBuffer.toString());
          _messages[_messages.length - 1] = updated;
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
        answerBuffer.write('\n\n**Error:** $e');
        final updated = assistantMsg.copyWith(content: answerBuffer.toString());
        _messages[_messages.length - 1] = updated;
      }
    } finally {
      _isStreaming = false;
      _currentStep = SearchStep.idle;
      _statusText = '';
      _activeSub = null;
      _activeClient?.close();
      _activeClient = null;

      final finalAssistantMsg = _messages.last;
      await _saveMessageToDb(finalAssistantMsg);
      notifyListeners();
    }
  }

  Future<void> _saveMessageToDb(ThreadMessage msg) async {
    final db = await DatabaseService.database;
    await db.insert('messages', msg.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
