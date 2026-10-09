import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../notebook/models.dart';
import '../notebook/notebook_service.dart';
import 'audio_overview_card.dart';

class GroundedChatView extends StatefulWidget {
  final NotebookService notebookService;

  const GroundedChatView({super.key, required this.notebookService});

  @override
  State<GroundedChatView> createState() => _GroundedChatViewState();
}

class _GroundedChatViewState extends State<GroundedChatView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
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

  void _handleAsk() {
    final query = _inputController.text.trim();
    if (query.isEmpty) return;

    _inputController.clear();
    widget.notebookService.askNotebook(query);
    _scrollToBottom();
  }

  void _showCitationModal(Citation citation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Row(
          children: [
            const Icon(Icons.menu_book, color: Color(0xFF6C8CFF), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${citation.sourceTitle} (Page ${citation.pageNumber})',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SelectableText(
          citation.snippet,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFF6C8CFF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notebookService,
      builder: (context, _) {
        final messages = widget.notebookService.messages;
        final currentNb = widget.notebookService.currentNotebook;
        final isStreaming = widget.notebookService.isStreamingChat;

        if (isStreaming) {
          _scrollToBottom();
        }

        return Container(
          color: const Color(0xFF141824),
          child: Column(
            children: [
              // Audio overview player card at top
              AudioOverviewCard(notebookService: widget.notebookService),

              // Chat transcript
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_stories, color: Color(0xFF6C8CFF), size: 40),
                            const SizedBox(height: 12),
                            Text(
                              currentNb?.title ?? 'Grounded Research Chat',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Ask anything about your uploaded sources.\nEvery claim cites the source name and exact page.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isUser = msg.role == 'user';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      isUser ? Icons.person : Icons.auto_awesome,
                                      size: 14,
                                      color: isUser ? Colors.white60 : const Color(0xFF6C8CFF),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isUser ? 'You' : 'NotebookLM',
                                      style: TextStyle(
                                        color: isUser ? Colors.white60 : const Color(0xFF6C8CFF),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  constraints: const BoxConstraints(maxWidth: 720),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isUser ? const Color(0xFF1E2638) : const Color(0xFF1B202E),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      MarkdownBody(
                                        data: msg.content.isEmpty && isStreaming && index == messages.length - 1
                                            ? 'Reading sources and synthesizing answer...'
                                            : msg.content,
                                        selectable: true,
                                        styleSheet: MarkdownStyleSheet(
                                          p: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.5),
                                          code: const TextStyle(
                                            color: Color(0xFF6C8CFF),
                                            backgroundColor: Color(0xFF11141E),
                                            fontFamily: 'Consolas',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),

                                      // Citations pill list
                                      if (msg.citations.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        const Divider(color: Colors.white10, height: 1),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            for (final c in msg.citations)
                                              InkWell(
                                                onTap: () => _showCitationModal(c),
                                                borderRadius: BorderRadius.circular(4),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF6C8CFF).withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: const Color(0xFF6C8CFF).withValues(alpha: 0.3)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.bookmark_outline, size: 12, color: Color(0xFF6C8CFF)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${c.sourceTitle}, p. ${c.pageNumber}',
                                                        style: const TextStyle(color: Color(0xFF6C8CFF), fontSize: 10, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Bottom query input bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B202E),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CallbackShortcuts(
                              bindings: {
                                const SingleActivator(LogicalKeyboardKey.enter): () {
                                  if (!HardwareKeyboard.instance.isShiftPressed) {
                                    _handleAsk();
                                  }
                                },
                              },
                              child: TextField(
                                controller: _inputController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Ask a question grounded in your sources...',
                                  hintStyle: TextStyle(color: Colors.white38),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isStreaming ? Icons.hourglass_top : Icons.arrow_upward,
                              color: const Color(0xFF6C8CFF),
                              size: 18,
                            ),
                            onPressed: isStreaming ? null : _handleAsk,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
