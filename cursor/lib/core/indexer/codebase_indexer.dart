import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import '../settings/settings_service.dart';

class CodeChunk {
  final String id;
  final String filePath;
  final int startLine;
  final int endLine;
  final String content;
  List<double>? embedding;
  Map<String, double>? termFreq;

  CodeChunk({
    required this.id,
    required this.filePath,
    required this.startLine,
    required this.endLine,
    required this.content,
    this.embedding,
    this.termFreq,
  });
}

class CodebaseIndexer extends ChangeNotifier {
  final SettingsService settingsService;
  String _projectPath = '';
  final List<CodeChunk> _chunks = [];
  bool _isIndexing = false;
  String _statusMessage = 'No project indexed';
  StreamSubscription<WatchEvent>? _watcherSub;

  CodebaseIndexer({required this.settingsService});

  String get projectPath => _projectPath;
  List<CodeChunk> get chunks => List.unmodifiable(_chunks);
  bool get isIndexing => _isIndexing;
  String get statusMessage => _statusMessage;

  void disposeWatcher() {
    _watcherSub?.cancel();
    _watcherSub = null;
  }

  Future<void> indexProject(String dirPath) async {
    _projectPath = dirPath;
    _isIndexing = true;
    _statusMessage = 'Scanning project files...';
    notifyListeners();

    _chunks.clear();
    disposeWatcher();

    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      _isIndexing = false;
      _statusMessage = 'Project directory not found';
      notifyListeners();
      return;
    }

    try {
      final files = await _findSourceFiles(dir);
      _statusMessage = 'Indexing ${files.length} source files...';
      notifyListeners();

      for (final file in files) {
        await _indexFile(file);
      }

      _statusMessage = 'Indexed ${_chunks.length} chunks across ${files.length} files';
    } catch (e) {
      _statusMessage = 'Indexing error: $e';
    } finally {
      _isIndexing = false;
      notifyListeners();
    }

    // Start watching for file saves
    _startWatcher();
  }

  void _startWatcher() {
    disposeWatcher();
    if (_projectPath.isEmpty) return;

    try {
      final watcher = DirectoryWatcher(_projectPath);
      _watcherSub = watcher.events.listen((event) async {
        if (event.type == ChangeType.MODIFY || event.type == ChangeType.ADD) {
          final file = File(event.path);
          if (await _shouldIndex(file)) {
            await _indexFile(file);
            _statusMessage = 'Updated index: ${p.basename(event.path)}';
            notifyListeners();
          }
        } else if (event.type == ChangeType.REMOVE) {
          final relPath = p.relative(event.path, from: _projectPath);
          _chunks.removeWhere((c) => c.filePath == relPath);
          _statusMessage = 'Removed from index: ${p.basename(event.path)}';
          notifyListeners();
        }
      });
    } catch (_) {}
  }

  Future<List<File>> _findSourceFiles(Directory dir) async {
    final results = <File>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && await _shouldIndex(entity)) {
        results.add(entity);
      }
    }
    return results;
  }

  Future<bool> _shouldIndex(File file) async {
    final path = file.path;
    final rel = p.relative(path, from: _projectPath);

    if (rel.startsWith('.') ||
        rel.contains('.git') ||
        rel.contains('build') ||
        rel.contains('.dart_tool') ||
        rel.contains('node_modules') ||
        rel.contains('ios') ||
        rel.contains('android') ||
        rel.contains('.idea') ||
        rel.contains('.vscode')) {
      return false;
    }

    final ext = p.extension(path).toLowerCase();
    const validExts = {
      '.dart', '.js', '.ts', '.jsx', '.tsx', '.py', '.rs', '.go', '.java',
      '.kt', '.c', '.cpp', '.h', '.cs', '.html', '.css', '.json', '.yaml', '.md',
    };
    if (!validExts.contains(ext)) return false;

    try {
      final length = await file.length();
      return length < 500000; // Skip files > 500KB
    } catch (_) {
      return false;
    }
  }

  Future<void> _indexFile(File file) async {
    final relPath = p.relative(file.path, from: _projectPath);
    _chunks.removeWhere((c) => c.filePath == relPath);

    try {
      final content = await file.readAsString();
      final lines = content.split('\n');

      const chunkSize = 50;
      const overlap = 10;

      for (int i = 0; i < lines.length; i += chunkSize - overlap) {
        final end = min(i + chunkSize, lines.length);
        final chunkText = lines.sublist(i, end).join('\n');
        if (chunkText.trim().isEmpty) continue;

        final chunk = CodeChunk(
          id: '${relPath}_${i + 1}_$end',
          filePath: relPath,
          startLine: i + 1,
          endLine: end,
          content: chunkText,
          termFreq: _computeTermFreq(chunkText),
        );
        _chunks.add(chunk);

        if (end >= lines.length) break;
      }
    } catch (_) {}
  }

  Map<String, double> _computeTermFreq(String text) {
    final tokens = text.toLowerCase().split(RegExp(r'[^\w]+')).where((t) => t.length > 2);
    final freq = <String, double>{};
    for (final t in tokens) {
      freq[t] = (freq[t] ?? 0.0) + 1.0;
    }
    return freq;
  }

  /// Searches the indexed codebase for the most relevant code chunks
  Future<List<CodeChunk>> searchCodebase(String query, {int topK = 6}) async {
    if (_chunks.isEmpty) return [];

    final queryTokens = query
        .toLowerCase()
        .split(RegExp(r'[^\w]+'))
        .where((t) => t.length > 2)
        .toSet();

    final scored = <MapEntry<CodeChunk, double>>[];

    for (final chunk in _chunks) {
      double score = 0.0;
      final textLower = chunk.content.toLowerCase();
      final pathLower = chunk.filePath.toLowerCase();

      // Query match in file path
      for (final t in queryTokens) {
        if (pathLower.contains(t)) score += 2.0;
      }

      // Exact query match in code
      if (textLower.contains(query.toLowerCase())) {
        score += 3.0;
      }

      // Term frequency overlap
      if (chunk.termFreq != null) {
        for (final t in queryTokens) {
          if (chunk.termFreq!.containsKey(t)) {
            score += 1.0 + (chunk.termFreq![t]! * 0.1);
          }
        }
      }

      if (score > 0) {
        scored.add(MapEntry(chunk, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(topK).map((e) => e.key).toList();
  }
}
