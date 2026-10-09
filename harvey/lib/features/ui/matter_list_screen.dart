import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/settings/settings_service.dart';
import '../contracts/contract_service.dart';
import '../matters/matter_repository.dart';
import '../matters/models/matter.dart';
import '../qa/legal_qa_service.dart';
import 'dialogs/settings_dialog.dart';
import 'matter_workspace_screen.dart';

class MatterListScreen extends StatefulWidget {
  final SettingsService settingsService;
  final MatterRepository repository;
  final ContractService contractService;
  final LegalQaService qaService;

  const MatterListScreen({
    super.key,
    required this.settingsService,
    required this.repository,
    required this.contractService,
    required this.qaService,
  });

  @override
  State<MatterListScreen> createState() => _MatterListScreenState();
}

class _MatterListScreenState extends State<MatterListScreen> {
  List<Matter> _matters = [];
  bool _isLoading = true;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadMatters();
  }

  Future<void> _loadMatters() async {
    setState(() => _isLoading = true);
    final matters = await widget.repository.getAllMatters();
    setState(() {
      _matters = matters;
      _isLoading = false;
    });
  }

  Future<void> _createNewMatter() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_special, color: Colors.indigoAccent),
            SizedBox(width: 8),
            Text('Create New Legal Matter'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Matter Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Project Orion (Series B Diligence)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              const Text('Description / Scope', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Review of customer master service agreements and commercial leases',
                  border: OutlineInputBorder(),
                ),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.indigo.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Create Matter'),
          ),
        ],
      ),
    );

    if (created == true) {
      final name = nameController.text.trim().isEmpty ? 'Untitled Matter' : nameController.text.trim();
      final desc = descController.text.trim();

      final matter = Matter(
        id: _uuid.v4(),
        name: name,
        description: desc,
        contracts: [],
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await widget.repository.saveMatter(matter);
      await _loadMatters();

      if (mounted) {
        _openMatter(matter);
      }
    }
  }

  Future<void> _openMatter(Matter matter) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatterWorkspaceScreen(
          initialMatter: matter,
          repository: widget.repository,
          contractService: widget.contractService,
          qaService: widget.qaService,
        ),
      ),
    );
    _loadMatters();
  }

  Future<void> _deleteMatter(Matter matter) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Matter?'),
        content: Text('Are you sure you want to delete "${matter.name}" and all its indexed contracts?'),
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
      await widget.repository.deleteMatter(matter.id);
      _loadMatters();
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
            Icon(Icons.gavel, color: Colors.indigoAccent),
            SizedBox(width: 10),
            Text(
              'Harvey Legal AI Studio',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.indigo.shade700),
            onPressed: _createNewMatter,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Legal Matter'),
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
          : _matters.isEmpty
              ? _buildEmptyState()
              : _buildMattersGrid(),
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
              color: Colors.indigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.gavel, size: 64, color: Colors.indigoAccent),
          ),
          const SizedBox(height: 20),
          const Text(
            'No legal matters found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 450,
            child: Text(
              'Create a matter to upload contracts, generate cross-contract clause review tables, and ask legal due diligence questions with passage citations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.indigo.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Create First Matter',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onPressed: _createNewMatter,
          ),
        ],
      ),
    );
  }

  Widget _buildMattersGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.45,
      ),
      itemCount: _matters.length,
      itemBuilder: (context, index) {
        final matter = _matters[index];

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          color: Theme.of(context).colorScheme.surface,
          child: InkWell(
            onTap: () => _openMatter(matter),
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
                          color: Colors.indigo.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.balance, size: 20, color: Colors.indigoAccent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          matter.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        tooltip: 'Delete',
                        onPressed: () => _deleteMatter(matter),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    matter.description.isNotEmpty ? matter.description : 'Legal matter workspace',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.description_outlined, size: 16, color: Colors.indigoAccent.shade100),
                      const SizedBox(width: 6),
                      Text(
                        '${matter.contracts.length} contracts',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'REVIEW READY',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigoAccent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 16, color: Colors.indigoAccent),
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
