import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../character/character_service.dart';
import 'character_memory_dialog.dart';

class ChatArenaView extends StatefulWidget {
  final CharacterService characterService;

  const ChatArenaView({super.key, required this.characterService});

  @override
  State<ChatArenaView> createState() => _ChatArenaViewState();
}

class _ChatArenaViewState extends State<ChatArenaView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isMicPressed = false;

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

  void _handleSend() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    widget.characterService.sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _startRecording() async {
    setState(() => _isMicPressed = true);
    await widget.characterService.voiceService.startRecording();
  }

  Future<void> _stopRecording() async {
    setState(() => _isMicPressed = false);
    final transcript = await widget.characterService.voiceService.stopRecordingAndTranscribe();
    if (transcript != null && transcript.trim().isNotEmpty) {
      _inputController.text = transcript.trim();
      _handleSend();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.characterService,
      builder: (context, _) {
        final char = widget.characterService.currentCharacter;
        final messages = widget.characterService.messages;
        final isGenerating = widget.characterService.isGenerating;
        final memoriesCount = widget.characterService.memories.length;

        if (char == null) {
          return const Center(child: Text('Select or create a character to begin chatting.'));
        }

        return Container(
          color: const Color(0xFF313338),
          child: Column(
            children: [
              // Character Header
              Container(
                height: 52,
                color: const Color(0xFF2B2D31),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF1E1F22),
                      radius: 16,
                      child: Text(char.avatar, style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          char.name,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Voice: ${char.voice} · Character AI',
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white12),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 30),
                      ),
                      icon: const Icon(Icons.psychology, size: 14, color: Color(0xFF5865F2)),
                      label: Text('Memory ($memoriesCount)', style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => CharacterMemoryDialog(characterService: widget.characterService),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg.role == 'user';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isUser) ...[
                            CircleAvatar(
                              backgroundColor: const Color(0xFF2B2D31),
                              radius: 14,
                              child: Text(char.avatar, style: const TextStyle(fontSize: 14)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isUser ? const Color(0xFF5865F2) : const Color(0xFF2B2D31),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.content,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                                  ),
                                  if (!isUser && msg.audioPath != null) ...[
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () => widget.characterService.voiceService.playAudio(msg.audioPath!),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.volume_up, size: 14, color: Color(0xFF5865F2)),
                                          SizedBox(width: 4),
                                          Text('Replay Voice', style: TextStyle(color: Color(0xFF5865F2), fontSize: 10, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              if (isGenerating)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5865F2))),
                      const SizedBox(width: 8),
                      Text('${char.name} is thinking and speaking...', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),

              // Input Bar & Push-to-Talk Mic
              Container(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF383A40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CallbackShortcuts(
                          bindings: {
                            const SingleActivator(LogicalKeyboardKey.enter): () {
                              if (!HardwareKeyboard.instance.isShiftPressed) {
                                _handleSend();
                              }
                            },
                          },
                          child: TextField(
                            controller: _inputController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Message ${char.name}...',
                              hintStyle: const TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Push to talk button
                    GestureDetector(
                      onTapDown: (_) => _startRecording(),
                      onTapUp: (_) => _stopRecording(),
                      onTapCancel: () => _stopRecording(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isMicPressed ? Colors.redAccent : const Color(0xFF2B2D31),
                        ),
                        child: Icon(
                          _isMicPressed ? Icons.mic : Icons.mic_none,
                          color: _isMicPressed ? Colors.white : Colors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 18, color: Color(0xFF5865F2)),
                      onPressed: isGenerating ? null : _handleSend,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
