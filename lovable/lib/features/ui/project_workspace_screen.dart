import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import '../agent/coding_agent_service.dart';
import '../preview/live_preview_pane.dart';
import '../projects/models/chat_message.dart';
import '../projects/models/project.dart';
import '../projects/project_repository.dart';
import '../server/project_server.dart';

class ProjectWorkspaceScreen extends StatefulWidget {
  final Project project;
  final ProjectRepository repository;
  final CodingAgentService agentService;

  const ProjectWorkspaceScreen({
    super.key,
    required this.project,
    required this.repository,
    required this.agentService,
  });

  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen> {
  final _projectServer = ProjectServer();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _previewKey = GlobalKey<LivePreviewPaneState>();
  final _uuid = const Uuid();

  List<ChatMessage> _messages = [];
  String? _serverUrl;
  bool _isCoding = false;
  String _codingStatus = '';

  final _quickChips = [
    'Make it dark mode',
    'Add category filter pills',
    'Add priority tags (High, Medium, Low)',
    'Add due date selector',
  ];

  @override
  void initState() {
    super.initState();
    _initWorkspace();
  }

  Future<void> _initWorkspace() async {
    // 1. Start local project web server
    final url = await _projectServer.start(widget.project.dirPath);
    setState(() => _serverUrl = url);

    // 2. Load chat history
    final messages = await widget.repository.getMessages(widget.project.id);
    setState(() => _messages = messages);

    // 3. If brand new project with 0 messages, generate initial app!
    if (messages.isEmpty) {
      _runInitialPrompt();
    }
  }

  Future<void> _runInitialPrompt() async {
    final prompt = widget.project.initialPrompt;
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      projectId: widget.project.id,
      role: 'user',
      content: prompt,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await widget.repository.saveMessage(userMsg);
    setState(() {
      _messages.add(userMsg);
      _isCoding = true;
      _codingStatus = 'Scaffolding full-stack React project on disk...';
    });

    try {
      final result = await widget.agentService.createNewApp(
        projectDir: widget.project.dirPath,
        appName: widget.project.name,
        prompt: prompt,
      );

      final assistantMsg = ChatMessage(
        id: _uuid.v4(),
        projectId: widget.project.id,
        role: 'assistant',
        content: result.assistantMessage,
        filesChanged: result.filesChanged,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await widget.repository.saveMessage(assistantMsg);
      await widget.repository.updateProjectTimestamp(widget.project.id);

      if (mounted) {
        setState(() {
          _messages.add(assistantMsg);
          _isCoding = false;
        });
        _previewKey.currentState?.reload();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCoding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Agent error: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = quickText ?? _inputController.text.trim();
    if (text.isEmpty || _isCoding) return;

    if (quickText == null) {
      _inputController.clear();
    }

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      projectId: widget.project.id,
      role: 'user',
      content: text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await widget.repository.saveMessage(userMsg);
    setState(() {
      _messages.add(userMsg);
      _isCoding = true;
      _codingStatus = 'Modifying files and updating live preview...';
    });
    _scrollToBottom();

    try {
      final result = await widget.agentService.modifyApp(
        projectDir: widget.project.dirPath,
        prompt: text,
      );

      final assistantMsg = ChatMessage(
        id: _uuid.v4(),
        projectId: widget.project.id,
        role: 'assistant',
        content: result.assistantMessage,
        filesChanged: result.filesChanged,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await widget.repository.saveMessage(assistantMsg);
      await widget.repository.updateProjectTimestamp(widget.project.id);

      if (mounted) {
        setState(() {
          _messages.add(assistantMsg);
          _isCoding = false;
        });
        _previewKey.currentState?.reload();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCoding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Agent error: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _projectServer.stop();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left 40%: Chat & Agent interaction pane
          SizedBox(
            width: 440,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161922),
                border: Border(
                  right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: Column(
                children: [
                  // App Bar / Top Navigation
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2230),
                      border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20),
                          tooltip: 'Back to Projects',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.project.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.project.dirPath,
                                style: const TextStyle(fontSize: 10, color: Colors.white54, fontFamily: 'monospace'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Messages list
                  Expanded(
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isUser = msg.role == 'user';

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 360),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.blueAccent.shade700 : const Color(0xFF222636),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isUser ? Colors.blueAccent : Colors.white12,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MarkdownBody(
                                  data: msg.content,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                                  ),
                                ),
                                if (msg.filesChanged.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: msg.filesChanged.map((f) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.white10),
                                        ),
                                        child: Text(
                                          f,
                                          style: const TextStyle(fontSize: 10, color: Colors.greenAccent, fontFamily: 'monospace'),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Coding progress banner
                  if (_isCoding)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.blue.withValues(alpha: 0.15),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _codingStatus,
                              style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Quick Suggestion Chips
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickChips.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final chip = _quickChips[index];
                        return ActionChip(
                          label: Text(chip, style: const TextStyle(fontSize: 11)),
                          onPressed: _isCoding ? null : () => _sendMessage(chip),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Bottom Prompt Input Bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2230),
                      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            decoration: const InputDecoration(
                              hintText: 'Ask Lovable to add a feature or redesign...',
                              hintStyle: TextStyle(fontSize: 13, color: Colors.white38),
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _isCoding ? null : () => _sendMessage(),
                          icon: const Icon(Icons.arrow_upward, size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right 60%: Live Preview Pane
          Expanded(
            child: LivePreviewPane(
              key: _previewKey,
              serverUrl: _serverUrl,
            ),
          ),
        ],
      ),
    );
  }
}
