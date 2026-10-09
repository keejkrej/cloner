import 'package:flutter/material.dart';
import '../../core/settings/settings_service.dart';
import '../notebook/notebook_service.dart';
import 'settings_dialog.dart';

class NotebookSidebar extends StatelessWidget {
  final NotebookService notebookService;
  final SettingsService settingsService;

  const NotebookSidebar({
    super.key,
    required this.notebookService,
    required this.settingsService,
  });

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B202E),
        title: const Text('New Notebook', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'e.g. Q3 Market Analysis',
            hintStyle: TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Color(0xFF141824),
          ),
          onSubmitted: (val) {
            notebookService.createNotebook(val);
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C8CFF)),
            onPressed: () {
              notebookService.createNotebook(controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFF11141E),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showCreateDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B202E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_box_outlined, color: Color(0xFF6C8CFF), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'New Notebook',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ListenableBuilder(
              listenable: notebookService,
              builder: (context, _) {
                final notebooks = notebookService.notebooks;
                final current = notebookService.currentNotebook;

                if (notebooks.isEmpty) {
                  return const Center(
                    child: Text('No notebooks', style: TextStyle(color: Colors.white30, fontSize: 11)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: notebooks.length,
                  itemBuilder: (context, index) {
                    final nb = notebooks[index];
                    final isSelected = current?.id == nb.id;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1E2638) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: const Icon(Icons.book_outlined, size: 16, color: Color(0xFF6C8CFF)),
                        title: Text(
                          nb.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, size: 14, color: Colors.white38),
                                onPressed: () => notebookService.deleteNotebook(nb.id),
                              )
                            : null,
                        onTap: () => notebookService.selectNotebook(nb.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => SettingsDialog(settingsService: settingsService),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 16, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('Settings', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
