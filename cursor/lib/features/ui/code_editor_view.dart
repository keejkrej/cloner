import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/autocomplete/autocomplete_service.dart';
import '../editor/editor_state.dart';

class CodeEditorView extends StatefulWidget {
  final EditorState editorState;
  final AutocompleteService autocompleteService;

  const CodeEditorView({
    super.key,
    required this.editorState,
    required this.autocompleteService,
  });

  @override
  State<CodeEditorView> createState() => _CodeEditorViewState();
}

class _CodeEditorViewState extends State<CodeEditorView> {
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.editorState.fileContent);

    widget.editorState.addListener(_onEditorStateChanged);
  }

  void _onEditorStateChanged() {
    if (_textController.text != widget.editorState.fileContent) {
      final oldSelection = _textController.selection;
      _textController.text = widget.editorState.fileContent;
      if (oldSelection.start <= _textController.text.length && oldSelection.end <= _textController.text.length) {
        _textController.selection = oldSelection;
      }
    }
  }

  @override
  void dispose() {
    widget.editorState.removeListener(_onEditorStateChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    widget.editorState.updateContent(text);

    final selection = _textController.selection;
    final cursorIndex = selection.baseOffset;
    if (cursorIndex >= 0 && cursorIndex <= text.length) {
      final prefix = text.substring(0, cursorIndex);
      final suffix = text.substring(cursorIndex);
      widget.autocompleteService.triggerAutocomplete(
        prefix: prefix,
        suffix: suffix,
        fileName: widget.editorState.currentFileName,
      );
    }
  }

  void _acceptAutocomplete() {
    final ghost = widget.autocompleteService.ghostText;
    if (ghost.isEmpty) return;

    final text = _textController.text;
    final selection = _textController.selection;
    final cursor = selection.baseOffset >= 0 ? selection.baseOffset : text.length;

    final before = text.substring(0, cursor);
    final after = text.substring(cursor);
    final newText = '$before$ghost$after';

    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(offset: cursor + ghost.length);
    widget.editorState.updateContent(newText);
    widget.autocompleteService.clearGhostText();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.editorState,
      builder: (context, _) {
        final currentFile = widget.editorState.currentFileName;
        final isDirty = widget.editorState.isDirty;
        final hasPendingDiff = widget.editorState.hasPendingDiff;
        final diffLines = widget.editorState.pendingDiffLines;

        if (widget.editorState.currentFilePath.isEmpty) {
          return Container(
            color: const Color(0xFF1E1E1E),
            child: const Center(
              child: Text(
                'Open a file from the explorer or ask the AI to generate code',
                style: TextStyle(color: Colors.white30, fontSize: 13),
              ),
            ),
          );
        }

        return Container(
          color: const Color(0xFF1E1E1E),
          child: Column(
            children: [
              // Top Tab / Header
              Container(
                height: 38,
                color: const Color(0xFF252526),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        border: Border(top: BorderSide(color: Color(0xFF007ACC), width: 2)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            currentFile,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          if (isDirty) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.save_outlined, size: 16, color: Colors.white70),
                      tooltip: 'Save (Ctrl+S)',
                      onPressed: () => widget.editorState.saveFile(),
                    ),
                  ],
                ),
              ),

              // Pending Diff Banner (Accept / Reject)
              if (hasPendingDiff && diffLines != null)
                Container(
                  color: const Color(0xFF2D2D30),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.difference_outlined, color: Color(0xFF007ACC), size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'AI Diff Edit Proposed',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                            onPressed: () => widget.editorState.rejectDiff(),
                            child: const Text('Reject (Discard)', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007ACC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            ),
                            onPressed: () => widget.editorState.acceptDiff(),
                            child: const Text('Accept Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: diffLines.length,
                          itemBuilder: (context, i) {
                            final line = diffLines[i];
                            final isAdd = line.type == '+';
                            final isDel = line.type == '-';
                            if (line.type == ' ' && diffLines.length > 8) return const SizedBox.shrink();

                            return Container(
                              color: isAdd
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : isDel
                                      ? Colors.red.withValues(alpha: 0.15)
                                      : Colors.transparent,
                              child: Text(
                                '${line.type} ${line.text}',
                                style: TextStyle(
                                  fontFamily: 'Consolas',
                                  fontSize: 11,
                                  color: isAdd
                                      ? Colors.greenAccent
                                      : isDel
                                          ? Colors.redAccent
                                          : Colors.white60,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Code Editor Area with Line Numbers and Ghost Text Overlay
              Expanded(
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
                      widget.editorState.saveFile();
                    },
                    const SingleActivator(LogicalKeyboardKey.tab): () {
                      if (widget.autocompleteService.ghostText.isNotEmpty) {
                        _acceptAutocomplete();
                      }
                    },
                  },
                  child: Stack(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Line numbers column
                          Container(
                            width: 44,
                            color: const Color(0xFF1E1E1E),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: ListenableBuilder(
                              listenable: _textController,
                              builder: (context, _) {
                                final lineCount = '\n'.allMatches(_textController.text).length + 1;
                                return ListView.builder(
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: lineCount,
                                  itemBuilder: (context, i) => Text(
                                    '${i + 1}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      color: Color(0xFF5A5A5A),
                                      fontFamily: 'Consolas',
                                      fontSize: 13,
                                      height: 1.45,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF282828)),
                          // Main text editor
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: TextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                maxLines: null,
                                expands: true,
                                keyboardType: TextInputType.multiline,
                                onChanged: _onTextChanged,
                                style: const TextStyle(
                                  color: Color(0xFFD4D4D4),
                                  fontFamily: 'Consolas',
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Ghost text autocomplete tooltip pill
                      ListenableBuilder(
                        listenable: widget.autocompleteService,
                        builder: (context, _) {
                          final ghost = widget.autocompleteService.ghostText;
                          if (ghost.isEmpty) return const SizedBox.shrink();

                          return Positioned(
                            right: 20,
                            bottom: 20,
                            child: InkWell(
                              onTap: _acceptAutocomplete,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252526),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF007ACC)),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.auto_awesome, color: Color(0xFF007ACC), size: 14),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tab: "$ghost"',
                                      style: const TextStyle(
                                        fontFamily: 'Consolas',
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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
