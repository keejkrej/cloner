import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/settings/settings_service.dart';
import '../settings/settings_dialog.dart';
import 'chat_service.dart';
import 'models.dart';

class ChatView extends StatefulWidget {
  final ChatService chatService;
  final SettingsService settingsService;

  const ChatView({
    super.key,
    required this.chatService,
    required this.settingsService,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
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

  void _handleSend() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    if (!widget.settingsService.hasValidApiKey) {
      showDialog(
        context: context,
        builder: (context) => SettingsDialog(settingsService: widget.settingsService),
      );
      return;
    }

    _textController.clear();
    widget.chatService.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.chatService,
      builder: (context, _) {
        final messages = widget.chatService.messages;
        final isStreaming = widget.chatService.isStreaming;

        if (isStreaming) {
          _scrollToBottom();
        }

        return Container(
          color: const Color(0xFF212121),
          child: Column(
            children: [
              // Api key warning if not set
              ListenableBuilder(
                listenable: widget.settingsService,
                builder: (context, _) {
                  if (widget.settingsService.hasValidApiKey) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    width: double.infinity,
                    color: Colors.amber.shade900.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Please configure your API key in Settings to start chatting.',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => SettingsDialog(settingsService: widget.settingsService),
                            );
                          },
                          child: const Text('Open Settings', style: TextStyle(color: Colors.amber)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Chat Messages Area
              Expanded(
                child: messages.isEmpty
                    ? _EmptyState(onPromptTap: (prompt) {
                        _textController.text = prompt;
                        _handleSend();
                      })
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isLast = index == messages.length - 1;
                          return _MessageRow(
                            message: msg,
                            isStreaming: isLast && isStreaming && msg.role == 'assistant',
                          );
                        },
                      ),
              ),

              // Bottom Input Bar & Stop Streaming Button
              _BottomInputBar(
                textController: _textController,
                focusNode: _focusNode,
                isStreaming: isStreaming,
                onSend: _handleSend,
                onStop: () => widget.chatService.stopStreaming(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ValueChanged<String> onPromptTap;

  const _EmptyState({required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2A2B32),
              ),
              child: const Icon(Icons.bolt, color: Color(0xFF10A37F), size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'What can I help with today?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PromptSuggestion(
                  text: 'Tell me a durable fact: "I am a Flutter engineer in Berlin"',
                  onTap: () => onPromptTap('Remember this about me: I am a Flutter engineer in Berlin and love building AI agents.'),
                ),
                _PromptSuggestion(
                  text: 'Explain quantum computing in simple terms',
                  onTap: () => onPromptTap('Explain quantum computing in simple terms with an analogy.'),
                ),
                _PromptSuggestion(
                  text: 'Write a Dart SSE streaming client function',
                  onTap: () => onPromptTap('Write a Dart function to parse Server-Sent Events line by line.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptSuggestion extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _PromptSuggestion({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
          color: const Color(0xFF2A2B32),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  final Message message;
  final bool isStreaming;

  const _MessageRow({
    required this.message,
    required this.isStreaming,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10A37F),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 14),
              ],
              Flexible(
                child: Container(
                  padding: isUser
                      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                      : EdgeInsets.zero,
                  decoration: isUser
                      ? BoxDecoration(
                          color: const Color(0xFF2F2F2F),
                          borderRadius: BorderRadius.circular(18),
                        )
                      : null,
                  child: isUser
                      ? Text(
                          message.content,
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.content.isEmpty && isStreaming)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10A37F)),
                                ),
                              )
                            else
                              MarkdownBody(
                                data: message.content,
                                selectable: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(color: Color(0xFFECECF1), fontSize: 14, height: 1.5),
                                  code: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    backgroundColor: Color(0xFF2D3748),
                                    fontFamily: 'Consolas',
                                    fontSize: 13,
                                  ),
                                  codeblockPadding: const EdgeInsets.all(12),
                                  codeblockDecoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  h1: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  h2: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  h3: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  listBullet: const TextStyle(color: Color(0xFFECECF1)),
                                ),
                              ),
                            if (isStreaming && message.content.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Container(
                                  width: 8,
                                  height: 14,
                                  color: const Color(0xFF10A37F),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomInputBar extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool isStreaming;
  final VoidCallback onSend;
  final VoidCallback onStop;

  const _BottomInputBar({
    required this.textController,
    required this.focusNode,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            children: [
              if (isStreaming)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      backgroundColor: const Color(0xFF2A2B32),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    icon: const Icon(Icons.stop, size: 16, color: Colors.redAccent),
                    label: const Text('Stop generating', style: TextStyle(fontSize: 13)),
                    onPressed: onStop,
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2F2F2F),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: CallbackShortcuts(
                        bindings: {
                          const SingleActivator(LogicalKeyboardKey.enter): () {
                            if (!HardwareKeyboard.instance.isShiftPressed) {
                              onSend();
                            }
                          },
                        },
                        child: TextField(
                          controller: textController,
                          focusNode: focusNode,
                          minLines: 1,
                          maxLines: 6,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Message ChatGPT...',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isStreaming ? Colors.redAccent : const Color(0xFF10A37F),
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                        icon: Icon(isStreaming ? Icons.stop : Icons.arrow_upward, size: 18),
                        onPressed: isStreaming ? onStop : onSend,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ChatGPT clone · Token-by-token streaming · Cross-chat memory · Local SQLite',
                style: TextStyle(color: Colors.white30, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
