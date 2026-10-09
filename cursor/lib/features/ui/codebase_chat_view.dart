import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import '../../core/indexer/codebase_indexer.dart';
import '../../core/settings/settings_service.dart';
import '../editor/editor_state.dart';

class CodebaseChatView extends StatefulWidget {
  final CodebaseIndexer indexer;
  final EditorState editorState;
  final SettingsService settingsService;

  const CodebaseChatView({
    super.key,
    required this.indexer,
    required this.editorState,
    required this.settingsService,
  });

  @override
  State<CodebaseChatView> createState() => _CodebaseChatViewState();
}

class _CodebaseChatViewState extends State<CodebaseChatView> {
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isGenerating = false;

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleAsk() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _isGenerating) return;

    if (!widget.settingsService.hasValidApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure API Key in Settings.')),
      );
      return;
    }

    _queryController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': query});
      _isGenerating = true;
    });
    _scrollToBottom();

    // Step 1: Codebase Index Retrieval
    final relevantChunks = await widget.indexer.searchCodebase(query, topK: 5);

    // Step 2: Context Building
    final contextBuffer = StringBuffer();
    if (relevantChunks.isNotEmpty) {
      contextBuffer.writeln('Retrieved relevant codebase context:');
      for (final chunk in relevantChunks) {
        contextBuffer.writeln('File: ${chunk.filePath} (lines ${chunk.startLine}-${chunk.endLine}):');
        contextBuffer.writeln('```\n${chunk.content}\n```\n');
      }
    }

    final activeFile = widget.editorState.currentFilePath;
    final activeCode = widget.editorState.fileContent;
    if (activeFile.isNotEmpty) {
      contextBuffer.writeln('Currently active open file: ${widget.editorState.currentFileName}');
      contextBuffer.writeln('```\n$activeCode\n```\n');
    }

    final systemInstruction = '''You are Cursor AI, a codebase assistant.
Answer questions accurately by referencing files, classes, and line numbers.
If the user asks to edit or change the active file, output the updated full code for the active file inside a single codeblock tagged with ````full_file_edit ... ```` so the editor can diff and apply it.''';

    final client = http.Client();
    try {
      var baseUrl = widget.settingsService.baseUrl.trim();
      if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);

      final response = await client.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.settingsService.apiKey}',
        },
        body: jsonEncode({
          'model': widget.settingsService.chatModel,
          'messages': [
            {'role': 'system', 'content': '$systemInstruction\n\n${contextBuffer.toString()}'},
            {'role': 'user', 'content': query},
          ],
          'temperature': 0.2,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final answer = json['choices']?[0]?['message']?['content'] as String? ?? 'No response.';

        // Check if an edit was proposed
        if (answer.contains('```full_file_edit')) {
          final start = answer.indexOf('```full_file_edit') + 17;
          final end = answer.indexOf('```', start);
          if (end != -1) {
            final proposedCode = answer.substring(start, end).trim();
            widget.editorState.proposeEdit(proposedCode);
          }
        }

        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': answer,
            'chunks': List<CodeChunk>.from(relevantChunks),
          });
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Error (${response.statusCode}): ${response.body}',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Failed to query LLM: $e',
        });
      });
    } finally {
      client.close();
      setState(() => _isGenerating = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      color: const Color(0xFF252526),
      child: Column(
        children: [
          // Header
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xFF222222),
            child: Row(
              children: [
                const Icon(Icons.psychology, size: 16, color: Color(0xFF007ACC)),
                const SizedBox(width: 8),
                const Text(
                  'Codebase AI',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ListenableBuilder(
                  listenable: widget.indexer,
                  builder: (context, _) {
                    return Tooltip(
                      message: widget.indexer.statusMessage,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.indexer.isIndexing ? Colors.amber : Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.indexer.isIndexing ? 'Indexing...' : '${widget.indexer.chunks.length} chunks',
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search, size: 32, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text(
                            'Ask anything about this repo',
                            style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'e.g. "Where is X handled?" or "Add error handling to this file"',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white30, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      final chunks = msg['chunks'] as List<CodeChunk>?;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUser ? 'You' : 'Cursor',
                              style: TextStyle(
                                color: isUser ? const Color(0xFF007ACC) : Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (chunks != null && chunks.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Referenced Code Chunks:', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                    for (final c in chunks)
                                      Text(
                                        '• ${c.filePath}:${c.startLine}-${c.endLine}',
                                        style: const TextStyle(color: Color(0xFF54C5F8), fontSize: 10, fontFamily: 'Consolas'),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            MarkdownBody(
                              data: msg['content'] as String,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(color: Colors.white, fontSize: 12),
                                code: const TextStyle(
                                  color: Color(0xFFD4D4D4),
                                  backgroundColor: Color(0xFF1E1E1E),
                                  fontFamily: 'Consolas',
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF1E1E1E),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    onSubmitted: (_) => _handleAsk(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Ask codebase or prompt edit...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: _isGenerating
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF007ACC)))
                      : const Icon(Icons.arrow_upward, size: 16, color: Color(0xFF007ACC)),
                  onPressed: _isGenerating ? null : _handleAsk,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
