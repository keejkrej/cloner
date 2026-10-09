import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../core/diff/diff_engine.dart';

class EditorState extends ChangeNotifier {
  String _currentFilePath = '';
  String _fileContent = '';
  bool _isDirty = false;

  String? _pendingEditProposed;
  List<DiffLineItem>? _pendingDiffLines;

  String get currentFilePath => _currentFilePath;
  String get currentFileName => _currentFilePath.isEmpty ? 'Untitled' : p.basename(_currentFilePath);
  String get fileContent => _fileContent;
  bool get isDirty => _isDirty;
  bool get hasPendingDiff => _pendingEditProposed != null;
  List<DiffLineItem>? get pendingDiffLines => _pendingDiffLines;

  Future<void> openFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return;

    _currentFilePath = path;
    _fileContent = await file.readAsString();
    _isDirty = false;
    _pendingEditProposed = null;
    _pendingDiffLines = null;
    notifyListeners();
  }

  void updateContent(String newContent) {
    if (_fileContent != newContent) {
      _fileContent = newContent;
      _isDirty = true;
      notifyListeners();
    }
  }

  Future<void> saveFile() async {
    if (_currentFilePath.isEmpty) return;

    final file = File(_currentFilePath);
    await file.writeAsString(_fileContent);
    _isDirty = false;
    notifyListeners();
  }

  void proposeEdit(String proposedContent) {
    _pendingEditProposed = proposedContent;
    _pendingDiffLines = DiffEngine.computeDiff(_fileContent, proposedContent);
    notifyListeners();
  }

  Future<void> acceptDiff() async {
    if (_pendingEditProposed == null) return;

    _fileContent = _pendingEditProposed!;
    _pendingEditProposed = null;
    _pendingDiffLines = null;
    _isDirty = false;

    if (_currentFilePath.isNotEmpty) {
      final file = File(_currentFilePath);
      await file.writeAsString(_fileContent);
    }
    notifyListeners();
  }

  void rejectDiff() {
    _pendingEditProposed = null;
    _pendingDiffLines = null;
    notifyListeners();
  }
}
