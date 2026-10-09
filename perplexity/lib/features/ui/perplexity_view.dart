import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/settings/settings_service.dart';
import '../search/models.dart';
import '../thread/thread_service.dart';
import 'settings_dialog.dart';
import 'sources_view.dart';

class PerplexityView extends StatefulWidget {
  final ThreadService threadService;
  final SettingsService settingsService;

  const PerplexityView({
    super.key,
    required this.threadService,
    required this.settingsService,
  });

  @override
  State<PerplexityView> createState() => _PerplexityViewState();
}

class _PerplexityViewState extends State<PerplexityView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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

  void _handleSubmit() {
    final query = _textController.text.trim();
    if (query.isEmpty) return;

    if (!widget.settingsService.hasLlmKey) {
      showDialog(
        context: context,
        builder: (context) => SettingsDialog(settingsService: widget.settingsService),
      );
      return;
    }

    _textController.clear();
    widget.threadService.submitQuery(query);
    _scrollToBottom();
  }

  Future<void> _handleLinkTap(String? href) async {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.threadService,
      builder: (context, _) {
        final messages = widget.threadService.messages;
        final sources = widget.threadService.currentSources;
        final step = widget.threadService.currentStep;
        final statusText = widget.threadService.statusText;
        final isStreaming = widget.threadService.isStreaming;

        if (isStreaming) {
          _scrollToBottom();
        }

        return Container(
          color: const Color(0xFF191E24),
          child: Column(
            children: [
              // Setup warning if no LLM key
              ListenableBuilder(
                listenable: widget.settingsService,
                builder: (context, _) {
                  if (widget.settingsService.hasLlmKey) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    color: Colors.amber.shade900.withValues(alpha: 0.25),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Enter your LLM API Key to search and synthesize answers with live citations.',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => SettingsDialog(settingsService: widget.settingsService),
                            );
                          },
                          child: const Text('Open Settings', style: TextStyle(color: Color(0xFF20B8CD), fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Main Body
              Expanded(
                child: messages.isEmpty
                    ? _EmptySearchHero(onSelectPrompt: (p) {
                        _textController.text = p;
                        _handleSubmit();
                      })
                    : ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 820),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Sources cards row
                                  if (sources.isNotEmpty) ...[
                                    SourcesView(sources: sources),
                                    const SizedBox(height: 20),
                                  ],

                                  // Status indicator if searching or reranking
                                  if (step != SearchStep.idle && step != SearchStep.generating)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        children: [
                                          const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF20B8CD)),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            statusText,
                                            style: const TextStyle(color: Color(0xFF20B8CD), fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Messages list
                                  for (int i = 0; i < messages.length; i++) ...[
                                    _MessageCard(
                                      message: messages[i],
                                      isStreaming: isStreaming && i == messages.length - 1,
                                      onLinkTap: _handleLinkTap,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              // Bottom query input bar
              _BottomSearchInput(
                textController: _textController,
                focusNode: _focusNode,
                isStreaming: isStreaming,
                onSubmit: _handleSubmit,
                onStop: () => widget.threadService.stopStreaming(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptySearchHero extends StatelessWidget {
  final ValueChanged<String> onSelectPrompt;

  const _EmptySearchHero({required this.onSelectPrompt});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.travel_explore, color: Color(0xFF20B8CD), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Where knowledge begins',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Live web search · Cohere/Jina/BM25 reranker · Grounded inline citations',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _ExampleQueryChip(
                  label: 'Latest breakthroughs in quantum computing 2026',
                  onTap: () => onSelectPrompt('What are the latest breakthroughs in quantum computing in 2026?'),
                ),
                _ExampleQueryChip(
                  label: 'How does Cohere Rerank work under the hood?',
                  onTap: () => onSelectPrompt('How does Cohere Rerank work under the hood?'),
                ),
                _ExampleQueryChip(
                  label: 'Compare Flutter Desktop performance vs Electron',
                  onTap: () => onSelectPrompt('Compare Flutter Desktop performance versus Electron for AI apps.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleQueryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ExampleQueryChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF212832),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final ThreadMessage message;
  final bool isStreaming;
  final ValueChanged<String?> onLinkTap;

  const _MessageCard({
    required this.message,
    required this.isStreaming,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          message.content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.4,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF20B8CD), size: 16),
              const SizedBox(width: 8),
              const Text(
                'Answer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isStreaming)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF20B8CD).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Live streaming...', style: TextStyle(color: Color(0xFF20B8CD), fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: message.content.isEmpty && isStreaming ? 'Searching and reading sources...' : message.content,
            selectable: true,
            onTapLink: (text, href, title) => onLinkTap(href),
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14, height: 1.6),
              h1: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              h2: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              h3: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              code: const TextStyle(
                color: Color(0xFF20B8CD),
                backgroundColor: Color(0xFF1E2630),
                fontFamily: 'Consolas',
                fontSize: 12,
              ),
              codeblockPadding: const EdgeInsets.all(12),
              codeblockDecoration: BoxDecoration(
                color: const Color(0xFF13171C),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSearchInput extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool isStreaming;
  final VoidCallback onSubmit;
  final VoidCallback onStop;

  const _BottomSearchInput({
    required this.textController,
    required this.focusNode,
    required this.isStreaming,
    required this.onSubmit,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              if (isStreaming)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      backgroundColor: const Color(0xFF212832),
                      side: const BorderSide(color: Colors.white12),
                    ),
                    icon: const Icon(Icons.stop, size: 14, color: Colors.redAccent),
                    label: const Text('Stop generating', style: TextStyle(fontSize: 12)),
                    onPressed: onStop,
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF20262E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF20B8CD), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CallbackShortcuts(
                        bindings: {
                          const SingleActivator(LogicalKeyboardKey.enter): () {
                            if (!HardwareKeyboard.instance.isShiftPressed) {
                              onSubmit();
                            }
                          },
                        },
                        child: TextField(
                          controller: textController,
                          focusNode: focusNode,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Ask anything or follow up with cited sources...',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(isStreaming ? Icons.stop : Icons.arrow_upward, size: 18),
                      color: isStreaming ? Colors.redAccent : const Color(0xFF20B8CD),
                      onPressed: isStreaming ? onStop : onSubmit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Perplexity clone · Search → Rerank → Grounded LLM generation with inline citations',
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
