import 'package:flutter/material.dart';
import 'memory_service.dart';

class MemoryDialog extends StatefulWidget {
  final MemoryService memoryService;

  const MemoryDialog({super.key, required this.memoryService});

  @override
  State<MemoryDialog> createState() => _MemoryDialogState();
}

class _MemoryDialogState extends State<MemoryDialog> {
  final _addFactController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _addFactController.dispose();
    super.dispose();
  }

  void _handleAdd() async {
    final text = _addFactController.text.trim();
    if (text.isEmpty) return;
    await widget.memoryService.addManualMemory(text);
    _addFactController.clear();
    setState(() => _isAdding = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.memoryService,
      builder: (context, _) {
        final memories = widget.memoryService.memories;

        return Dialog(
          backgroundColor: const Color(0xFF202123),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology, color: Color(0xFF10A37F), size: 24),
                          const SizedBox(width: 10),
                          const Text(
                            'ChatGPT Memory',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2B32),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${memories.length}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Facts remembered about you across conversations. Used automatically in future chats.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (_isAdding) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addFactController,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'e.g. Prefers answers in concise bullet points',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xFF2A2B32),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onSubmitted: (_) => _handleAdd(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.check, color: Color(0xFF10A37F)),
                          onPressed: _handleAdd,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => setState(() => _isAdding = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add fact manually', style: TextStyle(fontSize: 13)),
                      onPressed: () => setState(() => _isAdding = true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Divider(color: Colors.white12),
                  Expanded(
                    child: memories.isEmpty
                        ? const Center(
                            child: Text(
                              'No memories yet.\nAs you chat, facts will be automatically remembered.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            itemCount: memories.length,
                            separatorBuilder: (context, _) => const Divider(color: Colors.white10, height: 1),
                            itemBuilder: (context, index) {
                              final mem = memories[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.circle, size: 6, color: Color(0xFF10A37F)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        mem.fact,
                                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white38),
                                      hoverColor: Colors.red.withValues(alpha: 0.1),
                                      onPressed: () => widget.memoryService.deleteMemory(mem.id),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
