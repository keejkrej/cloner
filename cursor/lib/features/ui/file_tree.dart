import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../editor/editor_state.dart';

class FileTree extends StatelessWidget {
  final String rootPath;
  final EditorState editorState;

  const FileTree({
    super.key,
    required this.rootPath,
    required this.editorState,
  });

  @override
  Widget build(BuildContext context) {
    if (rootPath.isEmpty) {
      return Container(
        color: const Color(0xFF181818),
        child: const Center(
          child: Text('No project open', style: TextStyle(color: Colors.white30, fontSize: 12)),
        ),
      );
    }

    final rootDir = Directory(rootPath);
    if (!rootDir.existsSync()) {
      return Container(
        color: const Color(0xFF181818),
        child: const Center(
          child: Text('Folder does not exist', style: TextStyle(color: Colors.white30, fontSize: 12)),
        ),
      );
    }

    return Container(
      color: const Color(0xFF181818),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                const Icon(Icons.folder, size: 14, color: Color(0xFF888888)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p.basename(rootPath).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: _DirectoryView(
              dir: rootDir,
              editorState: editorState,
              depth: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectoryView extends StatelessWidget {
  final Directory dir;
  final EditorState editorState;
  final int depth;

  const _DirectoryView({
    required this.dir,
    required this.editorState,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    List<FileSystemEntity> entities = [];
    try {
      entities = dir.listSync()
        ..sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir && !bIsDir) return -1;
          if (!aIsDir && bIsDir) return 1;
          return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
        });
    } catch (_) {}

    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        for (final entity in entities)
          if (!p.basename(entity.path).startsWith('.') &&
              p.basename(entity.path) != 'build' &&
              p.basename(entity.path) != 'node_modules' &&
              p.basename(entity.path) != '.dart_tool')
            if (entity is Directory)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.only(left: 12.0 + (depth * 8), right: 8),
                  visualDensity: VisualDensity.compact,
                  dense: true,
                  leading: const Icon(Icons.folder_outlined, size: 14, color: Color(0xFFD4A373)),
                  title: Text(
                    p.basename(entity.path),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  children: [
                    _DirectoryView(
                      dir: entity,
                      editorState: editorState,
                      depth: depth + 1,
                    ),
                  ],
                ),
              )
            else
              ListenableBuilder(
                listenable: editorState,
                builder: (context, _) {
                  final isSelected = editorState.currentFilePath == entity.path;
                  return InkWell(
                    onTap: () => editorState.openFile(entity.path),
                    child: Container(
                      color: isSelected ? const Color(0xFF2A2D2E) : Colors.transparent,
                      padding: EdgeInsets.fromLTRB(16.0 + (depth * 8), 4, 8, 4),
                      child: Row(
                        children: [
                          Icon(
                            _getFileIcon(entity.path),
                            size: 14,
                            color: _getFileColor(entity.path),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p.basename(entity.path),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  IconData _getFileIcon(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.dart':
        return Icons.flutter_dash;
      case '.json':
      case '.yaml':
        return Icons.data_object;
      case '.md':
        return Icons.description;
      default:
        return Icons.code;
    }
  }

  Color _getFileColor(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.dart':
        return const Color(0xFF54C5F8);
      case '.json':
      case '.yaml':
        return const Color(0xFFF9C74F);
      case '.md':
        return const Color(0xFF90BE6D);
      default:
        return Colors.white54;
    }
  }
}
