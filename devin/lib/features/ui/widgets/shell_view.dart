import 'package:flutter/material.dart';

class ShellView extends StatefulWidget {
  final Stream<String> outputStream;
  final List<String> initialHistory;
  final VoidCallback onClear;

  const ShellView({
    super.key,
    required this.outputStream,
    required this.initialHistory,
    required this.onClear,
  });

  @override
  State<ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<ShellView> {
  final List<String> _lines = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _lines.addAll(widget.initialHistory);
    widget.outputStream.listen((line) {
      if (mounted) {
        setState(() {
          _lines.add(line);
        });
        _scrollToBottom();
      }
    });
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1117),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF161B22),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 16, color: Colors.greenAccent),
                const SizedBox(width: 8),
                const Text(
                  'Devin Autonomous Shell & Test Runner',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () {
                    widget.onClear();
                    setState(() => _lines.clear());
                  },
                  icon: const Icon(Icons.clear_all, size: 14, color: Colors.grey),
                  label: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _lines.isEmpty
                ? const Center(
                    child: Text('Shell idle. Command execution logs will stream here.',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _lines.length,
                    itemBuilder: (context, index) {
                      final line = _lines[index];
                      final isCmd = line.startsWith('\$ ');
                      final isErr = line.startsWith('[ERR]');
                      final isPass = line.contains('All tests passed') || line.contains('Clean status');

                      Color textColor = Colors.white.withValues(alpha: 0.85);
                      if (isCmd) textColor = Colors.cyanAccent;
                      if (isErr) textColor = Colors.redAccent;
                      if (isPass) textColor = Colors.greenAccent;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          line,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: textColor,
                            fontWeight: isCmd ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
