import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../notebook/notebook_service.dart';

class SourcesPanel extends StatelessWidget {
  final NotebookService notebookService;

  const SourcesPanel({super.key, required this.notebookService});

  Future<void> _pickAndAddSource() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md'],
    );

    if (result.isNotEmpty && result.first.path != null) {
      await notebookService.addSourceFile(result.first.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF141824),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.folder_shared_outlined, size: 16, color: Color(0xFF6C8CFF)),
                    SizedBox(width: 8),
                    Text(
                      'Sources',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ListenableBuilder(
                  listenable: notebookService,
                  builder: (context, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C8CFF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${notebookService.sources.length}',
                        style: const TextStyle(color: Color(0xFF6C8CFF), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white12),
                backgroundColor: const Color(0xFF1E2436),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(double.infinity, 36),
              ),
              icon: const Icon(Icons.upload_file, size: 16, color: Color(0xFF6C8CFF)),
              label: const Text('Add PDF / Document', style: TextStyle(fontSize: 12)),
              onPressed: _pickAndAddSource,
            ),
          ),
          const SizedBox(height: 6),
          ListenableBuilder(
            listenable: notebookService,
            builder: (context, _) {
              if (notebookService.isIngesting) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  child: const Row(
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C8CFF))),
                      SizedBox(width: 10),
                      Text('Ingesting & chunking...', style: TextStyle(color: Color(0xFF6C8CFF), fontSize: 11)),
                    ],
                  ),
                );
              }

              final sources = notebookService.sources;
              if (sources.isEmpty) {
                return const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No sources added yet.\nUpload 1 or more PDFs to begin grounded research.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    ),
                  ),
                );
              }

              return Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  itemCount: sources.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final s = sources[index];
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B202E),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${s.pageCount} ${s.pageCount == 1 ? "page" : "pages"} indexed',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
