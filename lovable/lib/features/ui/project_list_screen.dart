import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/settings/settings_service.dart';
import '../agent/coding_agent_service.dart';
import '../projects/models/project.dart';
import '../projects/project_repository.dart';
import 'dialogs/settings_dialog.dart';
import 'project_workspace_screen.dart';

class ProjectListScreen extends StatefulWidget {
  final SettingsService settingsService;
  final ProjectRepository repository;
  final CodingAgentService agentService;

  const ProjectListScreen({
    super.key,
    required this.settingsService,
    required this.repository,
    required this.agentService,
  });

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  List<Project> _projects = [];
  bool _isLoading = true;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final projects = await widget.repository.getAllProjects();
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
  }

  Future<void> _createNewProject() async {
    final nameController = TextEditingController();
    final promptController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Create New App'),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Project Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. TaskMaster, NotesApp, Dashboard',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text('What would you like to build?', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: promptController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Build a todo app with categories and real-time filtering',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Todo App with Categories', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      nameController.text = 'TaskMaster';
                      promptController.text = 'Build a todo app with categories';
                    },
                  ),
                  ActionChip(
                    label: const Text('Finance & Asset Tracker', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      nameController.text = 'FinPulse';
                      promptController.text = 'Build a modern personal finance and asset tracker';
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Create & Build'),
          ),
        ],
      ),
    );

    if (created == true) {
      final name = nameController.text.trim().isEmpty ? 'Untitled App' : nameController.text.trim();
      final prompt = promptController.text.trim().isEmpty ? 'Build a todo app with categories' : promptController.text.trim();

      final id = _uuid.v4();
      final appDocDir = await getApplicationDocumentsDirectory();
      final projectDir = Directory(p.join(appDocDir.path, 'LovableClone', 'projects', id));
      if (!await projectDir.exists()) {
        await projectDir.create(recursive: true);
      }

      final project = Project(
        id: id,
        name: name,
        initialPrompt: prompt,
        dirPath: projectDir.path,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await widget.repository.saveProject(project);
      await _loadProjects();

      if (mounted) {
        _openProject(project);
      }
    }
  }

  Future<void> _openProject(Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectWorkspaceScreen(
          project: project,
          repository: widget.repository,
          agentService: widget.agentService,
        ),
      ),
    );
    _loadProjects();
  }

  Future<void> _deleteProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text('Are you sure you want to delete "${project.name}" and its files on disk?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.repository.deleteProject(project.id, project.dirPath);
      _loadProjects();
    }
  }

  Future<void> _openSettings() async {
    await showDialog(
      context: context,
      builder: (ctx) => SettingsDialog(settingsService: widget.settingsService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text(
              'Lovable Full-Stack Studio',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: _createNewProject,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New App'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? _buildEmptyState()
              : _buildProjectsGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.web, size: 64, color: Colors.blueAccent),
          ),
          const SizedBox(height: 20),
          const Text(
            'No apps created yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 450,
            child: Text(
              'Describe an idea and Lovable will scaffold a working multi-file React + Tailwind app on disk with instant live preview and hot reloading.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text(
              'Create Your First App',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onPressed: _createNewProject,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.4,
      ),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          color: Theme.of(context).colorScheme.surface,
          child: InkWell(
            onTap: () => _openProject(project),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.code, size: 20, color: Colors.blueAccent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          project.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                        tooltip: 'Delete',
                        onPressed: () => _deleteProject(project),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    project.initialPrompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.folder_outlined, size: 14, color: Colors.white38),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          project.dirPath.split(RegExp(r'[\\/]')).last,
                          style: const TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'monospace'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_forward, size: 16, color: Colors.blueAccent),
                    ],
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
