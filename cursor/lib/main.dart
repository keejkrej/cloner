import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'core/autocomplete/autocomplete_service.dart';
import 'core/indexer/codebase_indexer.dart';
import 'core/settings/settings_service.dart';
import 'features/editor/editor_state.dart';
import 'features/ui/code_editor_view.dart';
import 'features/ui/codebase_chat_view.dart';
import 'features/ui/file_tree.dart';
import 'features/ui/settings_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  await settingsService.init();

  final indexer = CodebaseIndexer(settingsService: settingsService);
  final editorState = EditorState();
  final autocompleteService = AutocompleteService(settingsService: settingsService);

  runApp(CursorCloneApp(
    settingsService: settingsService,
    indexer: indexer,
    editorState: editorState,
    autocompleteService: autocompleteService,
  ));
}

class CursorCloneApp extends StatefulWidget {
  final SettingsService settingsService;
  final CodebaseIndexer indexer;
  final EditorState editorState;
  final AutocompleteService autocompleteService;

  const CursorCloneApp({
    super.key,
    required this.settingsService,
    required this.indexer,
    required this.editorState,
    required this.autocompleteService,
  });

  @override
  State<CursorCloneApp> createState() => _CursorCloneAppState();
}

class _CursorCloneAppState extends State<CursorCloneApp> {
  String _projectPath = '';

  Future<void> _openProjectFolder() async {
    final selected = await FilePicker.getDirectoryPath();
    if (selected != null) {
      setState(() => _projectPath = selected);
      await widget.indexer.indexProject(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cursor Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF007ACC),
          surface: Color(0xFF252526),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF323233),
          elevation: 0,
          toolbarHeight: 38,
          title: Row(
            children: [
              const Icon(Icons.code, color: Color(0xFF007ACC), size: 16),
              const SizedBox(width: 8),
              const Text('Cursor', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 26),
                ),
                icon: const Icon(Icons.folder_open, size: 14),
                label: Text(
                  _projectPath.isEmpty ? 'Open Folder' : _projectPath,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: _openProjectFolder,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 16, color: Colors.white70),
              tooltip: 'Settings',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => SettingsDialog(settingsService: widget.settingsService),
                );
              },
            ),
          ],
        ),
        body: Row(
          children: [
            // Left: File Tree Explorer
            SizedBox(
              width: 220,
              child: FileTree(
                rootPath: _projectPath,
                editorState: widget.editorState,
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF2B2B2B)),

            // Center: Code Editor with Ghost-Text & Diff Edits
            Expanded(
              child: CodeEditorView(
                editorState: widget.editorState,
                autocompleteService: widget.autocompleteService,
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF2B2B2B)),

            // Right: Codebase Chat & Diff Generator
            CodebaseChatView(
              indexer: widget.indexer,
              editorState: widget.editorState,
              settingsService: widget.settingsService,
            ),
          ],
        ),
      ),
    );
  }
}
