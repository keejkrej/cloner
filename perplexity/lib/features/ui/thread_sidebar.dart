import 'package:flutter/material.dart';
import '../../core/settings/settings_service.dart';
import '../search/models.dart';
import '../thread/thread_service.dart';
import 'settings_dialog.dart';

class ThreadSidebar extends StatelessWidget {
  final ThreadService threadService;
  final SettingsService settingsService;

  const ThreadSidebar({
    super.key,
    required this.threadService,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF13171C),
      child: Column(
        children: [
          // New Search Button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => threadService.startNewThread(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                  color: const Color(0xFF1A2027),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF20B8CD), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'New Thread',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.add, color: Colors.white38, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Thread History
          Expanded(
            child: ListenableBuilder(
              listenable: threadService,
              builder: (context, _) {
                final threads = threadService.threads;
                final current = threadService.currentThread;

                if (threads.isEmpty) {
                  return const Center(
                    child: Text(
                      'No searches yet',
                      style: TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: threads.length,
                  itemBuilder: (context, index) {
                    final t = threads[index];
                    final isSelected = current?.id == t.id;

                    return _ThreadTile(
                      thread: t,
                      isSelected: isSelected,
                      onTap: () => threadService.selectThread(t.id),
                      onDelete: () => threadService.deleteThread(t.id),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Footer
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListenableBuilder(
              listenable: settingsService,
              builder: (context, _) {
                final hasKey = settingsService.hasLlmKey;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SettingsDialog(settingsService: settingsService),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.settings_outlined, size: 18, color: Colors.white70),
                        const SizedBox(width: 10),
                        const Text(
                          'Settings',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const Spacer(),
                        if (!hasKey)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade900.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Setup', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
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

class _ThreadTile extends StatefulWidget {
  final SearchThread thread;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ThreadTile({
    required this.thread,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_ThreadTile> createState() => _ThreadTileState();
}

class _ThreadTileState extends State<_ThreadTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? const Color(0xFF1E2630)
              : _isHovered
                  ? const Color(0xFF171D24)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          title: Text(
            widget.thread.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.isSelected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          trailing: (_isHovered || widget.isSelected)
              ? IconButton(
                  icon: const Icon(Icons.delete_outline, size: 15, color: Colors.white38),
                  hoverColor: Colors.red.withValues(alpha: 0.15),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onDelete,
                )
              : null,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}
