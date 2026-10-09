import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/settings/settings_service.dart';
import '../generator/workflow_generator_service.dart';
import '../runner/workflow_runner_service.dart';
import '../workflows/models/workflow.dart';
import '../workflows/models/workflow_run.dart';
import '../workflows/workflow_repository.dart';
import 'dialogs/create_workflow_dialog.dart';
import 'dialogs/settings_dialog.dart';
import 'widgets/run_history_view.dart';
import 'widgets/step_flow_view.dart';
import 'widgets/workflow_card.dart';

class ZapierHomeScreen extends StatefulWidget {
  final WorkflowRepository repository;
  final WorkflowRunnerService runnerService;
  final WorkflowGeneratorService generatorService;
  final SettingsService settingsService;

  const ZapierHomeScreen({
    super.key,
    required this.repository,
    required this.runnerService,
    required this.generatorService,
    required this.settingsService,
  });

  @override
  State<ZapierHomeScreen> createState() => _ZapierHomeScreenState();
}

class _ZapierHomeScreenState extends State<ZapierHomeScreen> with SingleTickerProviderStateMixin {
  List<Workflow> _workflows = [];
  Workflow? _selectedWorkflow;
  List<WorkflowRun> _runs = [];
  bool _isLoading = true;
  bool _isRunning = false;
  String _filter = 'all'; // 'all', 'active', 'inactive'
  late TabController _tabController;
  StreamSubscription<WorkflowRun>? _runSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    widget.runnerService.startScheduler();

    _runSub = widget.runnerService.onRunUpdated.listen((run) {
      if (mounted) {
        setState(() {
          final idx = _runs.indexWhere((r) => r.id == run.id);
          if (idx >= 0) {
            _runs[idx] = run;
          } else {
            _runs.insert(0, run);
          }
          // Also update lastRunAt of workflow
          final wfIdx = _workflows.indexWhere((w) => w.id == run.workflowId);
          if (wfIdx >= 0) {
            _workflows[wfIdx] = _workflows[wfIdx].copyWith(lastRunAt: run.startedAt);
            if (_selectedWorkflow?.id == run.workflowId) {
              _selectedWorkflow = _workflows[wfIdx];
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _runSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final workflows = await widget.repository.getAllWorkflows();
    final recentRuns = await widget.repository.getRecentRuns();

    if (mounted) {
      setState(() {
        _workflows = workflows;
        if (_workflows.isNotEmpty) {
          _selectedWorkflow = _workflows.first;
        }
        _runs = recentRuns;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleActive(Workflow workflow, bool active) async {
    await widget.repository.updateWorkflowStatus(workflow.id, active);
    final updated = workflow.copyWith(isActive: active);
    setState(() {
      final idx = _workflows.indexWhere((w) => w.id == workflow.id);
      if (idx >= 0) {
        _workflows[idx] = updated;
      }
      if (_selectedWorkflow?.id == workflow.id) {
        _selectedWorkflow = updated;
      }
    });
  }

  Future<void> _deleteWorkflow(Workflow workflow) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Zap?'),
        content: Text('Are you sure you want to delete "${workflow.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.repository.deleteWorkflow(workflow.id);
      setState(() {
        _workflows.removeWhere((w) => w.id == workflow.id);
        if (_selectedWorkflow?.id == workflow.id) {
          _selectedWorkflow = _workflows.isNotEmpty ? _workflows.first : null;
        }
      });
    }
  }

  Future<void> _openCreateZapDialog() async {
    final newWf = await showDialog<Workflow>(
      context: context,
      builder: (ctx) => CreateWorkflowDialog(generatorService: widget.generatorService),
    );

    if (newWf != null) {
      await widget.repository.saveWorkflow(newWf);
      setState(() {
        _workflows.insert(0, newWf);
        _selectedWorkflow = newWf;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Zap "${newWf.title}" created successfully!')),
        );
      }
    }
  }

  Future<void> _runWorkflowNow(Workflow workflow) async {
    setState(() {
      _isRunning = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      final run = await widget.runnerService.executeWorkflow(workflow);
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Run completed for "${workflow.title}" (${run.status})'),
            backgroundColor: run.status == 'success' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
        messenger.showSnackBar(
          SnackBar(content: Text('Run error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SettingsDialog(settingsService: widget.settingsService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    final filteredWorkflows = _workflows.where((w) {
      if (_filter == 'active') return w.isActive;
      if (_filter == 'inactive') return !w.isActive;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Zapier AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_workflows.where((w) => w.isActive).length} active',
                style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: _openCreateZapDialog,
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('New Zap with AI'),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Connector Settings',
            onPressed: _openSettingsDialog,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          // Left Sidebar: Workflow List
          Container(
            width: 360,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2))),
              color: theme.cardColor.withValues(alpha: 0.4),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 6),
                      _buildFilterChip('Active', 'active'),
                      const SizedBox(width: 6),
                      _buildFilterChip('Inactive', 'inactive'),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filteredWorkflows.isEmpty
                      ? const Center(
                          child: Text('No workflows found', style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          itemCount: filteredWorkflows.length,
                          itemBuilder: (context, index) {
                            final wf = filteredWorkflows[index];
                            return WorkflowCard(
                              workflow: wf,
                              isSelected: _selectedWorkflow?.id == wf.id,
                              onTap: () {
                                setState(() {
                                  _selectedWorkflow = wf;
                                });
                              },
                              onToggleActive: (val) => _toggleActive(wf, val),
                              onRunNow: () => _runWorkflowNow(wf),
                              onDelete: () => _deleteWorkflow(wf),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // Right Content Area: Tabs for Flow & Logs
          Expanded(
            child: _selectedWorkflow == null
                ? const Center(child: Text('Select or create a Zap to view details'))
                : Column(
                    children: [
                      Container(
                        color: theme.cardColor,
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.orange,
                          labelColor: Colors.orange,
                          unselectedLabelColor: Colors.grey,
                          tabs: const [
                            Tab(icon: Icon(Icons.account_tree_outlined), text: 'Workflow Flow'),
                            Tab(icon: Icon(Icons.history), text: 'Run Logs & Executions'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            StepFlowView(
                              workflow: _selectedWorkflow!,
                              onRunNow: () => _runWorkflowNow(_selectedWorkflow!),
                              isRunning: _isRunning,
                            ),
                            RunHistoryView(
                              runs: _runs.where((r) => r.workflowId == _selectedWorkflow!.id).toList(),
                              onRefresh: _loadData,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: Colors.orange.withValues(alpha: 0.3),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filter = value;
          });
        }
      },
    );
  }
}
