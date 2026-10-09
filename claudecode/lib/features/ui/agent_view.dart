import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/diff/diff_service.dart';
import '../../core/settings/settings_service.dart';
import '../agent/agent_loop.dart';
import 'approval_dialog.dart';
import 'settings_dialog.dart';

class AgentView extends StatefulWidget {
  final AgentService agentService;
  final SettingsService settingsService;

  const AgentView({
    super.key,
    required this.agentService,
    required this.settingsService,
  });

  @override
  State<AgentView> createState() => _AgentViewState();
}

class _AgentViewState extends State<AgentView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Register approval handler to show modal dialog
    widget.agentService.approvalHandler = ({
      required String toolName,
      required String target,
      required String details,
      List<DiffLine>? diffLines,
    }) async {
      final approved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ApprovalDialog(
          toolName: toolName,
          target: target,
          details: details,
          diffLines: diffLines,
        ),
      );
      return approved ?? false;
    };
  }

  @override
  void dispose() {
    _inputController.dispose();
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

  Future<void> _pickDirectory() async {
    final selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory != null) {
      widget.agentService.setWorkingDir(selectedDirectory);
    }
  }

  void _handleSubmit() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    if (!widget.settingsService.hasValidApiKey) {
      showDialog(
        context: context,
        builder: (context) => SettingsDialog(settingsService: widget.settingsService),
      );
      return;
    }

    _inputController.clear();
    widget.agentService.runTask(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.agentService,
      builder: (context, _) {
        final transcript = widget.agentService.transcript;
        final isRunning = widget.agentService.isRunning;
        final workingDir = widget.agentService.workingDir;

        if (isRunning) {
          _scrollToBottom();
        }

        return Scaffold(
          backgroundColor: const Color(0xFF141414),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E1E1E),
            elevation: 1,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDA7756).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.terminal, color: Color(0xFFDA7756), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Claude Code',
                        style: TextStyle(
                          color: Color(0xFFDA7756),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    workingDir.isEmpty ? 'No directory selected' : workingDir,
                    style: TextStyle(
                      color: workingDir.isEmpty ? Colors.white38 : Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Consolas',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.folder_open, size: 16, color: Colors.white70),
                label: const Text('Open Project', style: TextStyle(color: Colors.white70, fontSize: 12)),
                onPressed: isRunning ? null : _pickDirectory,
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.white60),
                tooltip: 'Clear Transcript',
                onPressed: isRunning ? null : () => widget.agentService.clearTranscript(),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 18, color: Colors.white60),
                tooltip: 'Settings',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => SettingsDialog(settingsService: widget.settingsService),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Transcript list
              Expanded(
                child: transcript.isEmpty
                    ? _EmptyState(onSelectTask: (task) {
                        _inputController.text = task;
                        _handleSubmit();
                      })
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: transcript.length,
                        itemBuilder: (context, index) {
                          return _TranscriptRow(step: transcript[index]);
                        },
                      ),
              ),

              // Bottom prompt bar
              _BottomPromptBar(
                textController: _inputController,
                focusNode: _focusNode,
                isRunning: isRunning,
                onSubmit: _handleSubmit,
                onStop: () => widget.agentService.cancel(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ValueChanged<String> onSelectTask;

  const _EmptyState({required this.onSelectTask});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_alt_outlined, color: Color(0xFFDA7756), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Autonomous Coding Agent',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a project folder, give Claude Code a goal, and watch it inspect, edit, and test autonomously.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ActionChip(
                  label: const Text('Add a unit test and make it pass'),
                  onPressed: () => onSelectTask('Add a unit test for one of our core classes and ensure all tests pass.'),
                ),
                ActionChip(
                  label: const Text('Explore files and summarize project'),
                  onPressed: () => onSelectTask('List files in this project and explain what the main components do.'),
                ),
                ActionChip(
                  label: const Text('Run flutter test in sandbox'),
                  onPressed: () => onSelectTask('Run dart test or flutter test in the terminal and report results.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TranscriptRow extends StatelessWidget {
  final AgentStep step;

  const _TranscriptRow({required this.step});

  @override
  Widget build(BuildContext context) {
    switch (step.type) {
      case AgentStepType.userMessage:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFF333333),
                child: Icon(Icons.person, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    step.content,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );

      case AgentStepType.agentMessage:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFFDA7756),
                child: Icon(Icons.bolt, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: MarkdownBody(
                    data: step.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.45),
                      code: const TextStyle(
                        color: Color(0xFFDA7756),
                        backgroundColor: Color(0xFF141414),
                        fontFamily: 'Consolas',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case AgentStepType.toolCall:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 34),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF181C20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFDA7756).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.build_circle_outlined, size: 14, color: Color(0xFFDA7756)),
                const SizedBox(width: 8),
                Text(
                  'Tool: ${step.toolName}',
                  style: const TextStyle(
                    color: Color(0xFFDA7756),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Consolas',
                  ),
                ),
                if (step.toolArgs != null && step.toolArgs!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'args: ${step.toolArgs}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'Consolas'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

      case AgentStepType.toolResult:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (step.diffLines != null && step.diffLines!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Diff Output:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 4),
                      for (final line in step.diffLines!)
                        Container(
                          color: line.type == '+'
                              ? Colors.green.withValues(alpha: 0.15)
                              : line.type == '-'
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : Colors.transparent,
                          child: Text(
                            '${line.type} ${line.text}',
                            style: TextStyle(
                              fontFamily: 'Consolas',
                              fontSize: 11,
                              color: line.type == '+'
                                  ? Colors.greenAccent
                                  : line.type == '-'
                                      ? Colors.redAccent
                                      : Colors.white60,
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: SelectableText(
                    step.content,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Consolas'),
                  ),
                ),
            ],
          ),
        );

      case AgentStepType.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.content,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}

class _BottomPromptBar extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool isRunning;
  final VoidCallback onSubmit;
  final VoidCallback onStop;

  const _BottomPromptBar({
    required this.textController,
    required this.focusNode,
    required this.isRunning,
    required this.onSubmit,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          Row(
            children: [
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
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Ask Claude Code to build, test, edit or debug...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isRunning)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.stop, size: 16),
                  label: const Text('Stop'),
                  onPressed: onStop,
                )
              else
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFDA7756),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  onPressed: onSubmit,
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Claude Code clone · Agent Loop · File Tools · Terminal Sandbox · Jailed Paths',
            style: TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
