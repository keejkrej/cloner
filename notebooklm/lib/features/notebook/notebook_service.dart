import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/database_service.dart';
import '../../core/ingest/pdf_extractor.dart';
import '../../core/rag/rag_service.dart';
import '../../core/settings/settings_service.dart';
import '../../core/tts/tts_service.dart';
import 'models.dart';

class NotebookService extends ChangeNotifier {
  final SettingsService settingsService;
  final RagService ragService = RagService();
  late final TtsService ttsService;
  final _uuid = const Uuid();

  List<Notebook> _notebooks = [];
  Notebook? _currentNotebook;
  List<NotebookSource> _sources = [];
  List<NotebookMessage> _messages = [];
  AudioOverview? _audioOverview;

  bool _isIngesting = false;
  bool _isGeneratingAudio = false;
  String _audioProgressText = '';
  bool _isStreamingChat = false;

  NotebookService({required this.settingsService}) {
    ttsService = TtsService(settingsService: settingsService);
  }

  List<Notebook> get notebooks => List.unmodifiable(_notebooks);
  Notebook? get currentNotebook => _currentNotebook;
  List<NotebookSource> get sources => List.unmodifiable(_sources);
  List<NotebookMessage> get messages => List.unmodifiable(_messages);
  AudioOverview? get audioOverview => _audioOverview;
  bool get isIngesting => _isIngesting;
  bool get isGeneratingAudio => _isGeneratingAudio;
  String get audioProgressText => _audioProgressText;
  bool get isStreamingChat => _isStreamingChat;

  Future<void> init() async {
    await loadNotebooks();
    if (_notebooks.isNotEmpty) {
      await selectNotebook(_notebooks.first.id);
    } else {
      await createNotebook('My Notebook');
    }
  }

  Future<void> loadNotebooks() async {
    final db = await DatabaseService.database;
    final rows = await db.query('notebooks', orderBy: 'updated_at DESC');
    _notebooks = rows.map((r) => Notebook.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> selectNotebook(String id) async {
    final db = await DatabaseService.database;
    final rows = await db.query('notebooks', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;

    _currentNotebook = Notebook.fromMap(rows.first);

    // Load sources
    final srcRows = await db.query('sources', where: 'notebook_id = ?', whereArgs: [id]);
    _sources = srcRows.map((s) => NotebookSource.fromMap(s)).toList();

    // Load messages
    final msgRows = await db.query('messages', where: 'notebook_id = ?', whereArgs: [id], orderBy: 'created_at ASC');
    _messages = msgRows.map((m) => NotebookMessage.fromMap(m)).toList();

    // Load latest audio overview
    final audioRows = await db.query('audio_overviews', where: 'notebook_id = ?', whereArgs: [id], orderBy: 'created_at DESC');
    if (audioRows.isNotEmpty) {
      _audioOverview = AudioOverview.fromMap(audioRows.first);
    } else {
      _audioOverview = null;
    }

    notifyListeners();
  }

  Future<void> createNotebook(String title) async {
    final cleanTitle = title.trim().isEmpty ? 'Untitled Notebook' : title.trim();
    final nb = Notebook(
      id: _uuid.v4(),
      title: cleanTitle,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final db = await DatabaseService.database;
    await db.insert('notebooks', nb.toMap());

    _notebooks.insert(0, nb);
    _currentNotebook = nb;
    _sources = [];
    _messages = [];
    _audioOverview = null;
    notifyListeners();
  }

  Future<void> deleteNotebook(String id) async {
    final db = await DatabaseService.database;
    await db.delete('chunks', where: 'notebook_id = ?', whereArgs: [id]);
    await db.delete('sources', where: 'notebook_id = ?', whereArgs: [id]);
    await db.delete('messages', where: 'notebook_id = ?', whereArgs: [id]);
    await db.delete('audio_overviews', where: 'notebook_id = ?', whereArgs: [id]);
    await db.delete('notebooks', where: 'id = ?', whereArgs: [id]);

    _notebooks.removeWhere((n) => n.id == id);
    if (_currentNotebook?.id == id) {
      if (_notebooks.isNotEmpty) {
        await selectNotebook(_notebooks.first.id);
      } else {
        await createNotebook('My Notebook');
      }
    } else {
      notifyListeners();
    }
  }

  Future<void> addSourceFile(String filePath) async {
    if (_currentNotebook == null) return;

    _isIngesting = true;
    notifyListeners();

    try {
      final pages = await PdfExtractor.extractPages(filePath);
      if (pages.isEmpty) return;

      final sourceId = _uuid.v4();
      final title = p.basenameWithoutExtension(filePath);

      final newSource = NotebookSource(
        id: sourceId,
        notebookId: _currentNotebook!.id,
        title: title,
        filePath: filePath,
        pageCount: pages.length,
        createdAt: DateTime.now(),
      );

      final db = await DatabaseService.database;
      await db.insert('sources', newSource.toMap());

      await ragService.chunkAndIndexPages(
        notebookId: _currentNotebook!.id,
        sourceId: sourceId,
        sourceTitle: title,
        pages: pages,
      );

      _sources.add(newSource);
    } catch (e) {
      debugPrint('Error ingesting source: $e');
    } finally {
      _isIngesting = false;
      notifyListeners();
    }
  }

  Future<void> askNotebook(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || _isStreamingChat || _currentNotebook == null) return;

    final db = await DatabaseService.database;
    final userMsg = NotebookMessage(
      id: _uuid.v4(),
      notebookId: _currentNotebook!.id,
      role: 'user',
      content: cleanQuery,
      citations: [],
      createdAt: DateTime.now(),
    );
    _messages.add(userMsg);
    await db.insert('messages', userMsg.toMap());
    notifyListeners();

    // Step 1: Retrieve top chunks
    final relevantChunks = await ragService.retrieveRelevantChunks(
      notebookId: _currentNotebook!.id,
      query: cleanQuery,
      topK: 6,
    );

    final citations = relevantChunks.map((c) => Citation(
      sourceTitle: c.sourceTitle,
      pageNumber: c.pageNumber,
      snippet: c.content.length > 120 ? '${c.content.substring(0, 120)}...' : c.content,
    )).toList();

    // Step 2: Context Building
    final contextBuffer = StringBuffer();
    contextBuffer.writeln('Retrieved Sources from Notebook:');
    for (int i = 0; i < relevantChunks.length; i++) {
      final c = relevantChunks[i];
      contextBuffer.writeln('Source: "${c.sourceTitle}" (Page ${c.pageNumber}):\n${c.content}\n');
    }

    final systemInstruction = '''You are NotebookLM, a grounded research assistant.
Answer the user's question using ONLY the retrieved sources.
Always cite the source name and page number directly after claims, e.g. [Document A, p. 2].
If the information is not present in the sources, state that clearly.''';

    final assistantMsg = NotebookMessage(
      id: _uuid.v4(),
      notebookId: _currentNotebook!.id,
      role: 'assistant',
      content: '',
      citations: citations,
      createdAt: DateTime.now(),
    );
    _messages.add(assistantMsg);
    _isStreamingChat = true;
    notifyListeners();

    final client = http.Client();
    final answerBuffer = StringBuffer();

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
            {'role': 'system', 'content': '$systemInstruction\n\n${contextBuffer.toString()}'},
            ..._messages.sublist(0, _messages.length - 1).map((m) => {'role': m.role, 'content': m.content}),
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final answer = json['choices']?[0]?['message']?['content'] as String? ?? '';
        answerBuffer.write(answer);
      } else {
        answerBuffer.write('Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      answerBuffer.write('Error querying LLM: $e');
    } finally {
      client.close();
      _isStreamingChat = false;

      final finalAssistantMsg = assistantMsg.copyWith(content: answerBuffer.toString());
      _messages[_messages.length - 1] = finalAssistantMsg;
      await db.insert('messages', finalAssistantMsg.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      notifyListeners();
    }
  }

  Future<void> generateAudioOverview() async {
    if (_currentNotebook == null || _isGeneratingAudio) return;

    _isGeneratingAudio = true;
    _audioProgressText = 'Analyzing sources and writing 2-host podcast script...';
    notifyListeners();

    try {
      final sampleChunks = await ragService.retrieveRelevantChunks(
        notebookId: _currentNotebook!.id,
        query: _currentNotebook!.title,
        topK: 10,
      );

      final script = await ttsService.generatePodcastScript(
        notebookTitle: _currentNotebook!.title,
        sampleChunks: sampleChunks,
      );

      _audioProgressText = 'Synthesizing voice lines with Alex & Sam...';
      notifyListeners();

      final audioPath = await ttsService.synthesizePodcastAudio(
        notebookId: _currentNotebook!.id,
        script: script,
        onProgress: (current, total) {
          _audioProgressText = 'Synthesizing voices ($current / $total)...';
          notifyListeners();
        },
      );

      final overview = AudioOverview(
        id: _uuid.v4(),
        notebookId: _currentNotebook!.id,
        title: '${_currentNotebook!.title} - Audio Overview',
        audioPath: audioPath,
        script: script,
        createdAt: DateTime.now(),
      );

      final db = await DatabaseService.database;
      await db.insert('audio_overviews', overview.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

      _audioOverview = overview;
    } catch (e) {
      debugPrint('Error generating audio overview: $e');
    } finally {
      _isGeneratingAudio = false;
      _audioProgressText = '';
      notifyListeners();
    }
  }
}
