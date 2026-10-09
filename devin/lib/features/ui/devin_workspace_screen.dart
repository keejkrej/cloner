import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/settings/settings_service.dart';
import '../agent/devin_agent_service.dart';
import '../browser/devin_browser_service.dart';
import '../planner/models/plan_item.dart';
import '../shell/devin_shell_service.dart';
import 'dialogs/settings_dialog.dart';
import 'widgets/browser_view.dart';
import 'widgets/plan_view.dart';
import 'widgets/pr_view.dart';
import 'widgets/shell_view.dart';

class DevinWorkspaceScreen extends StatefulWidget {
  final DevinAgentService agentService;
  final DevinBrowserService browserService;
  final DevinShellService shellService;
  final SettingsService settingsService;

  const DevinWorkspaceScreen({
    super.key,
    required this.agentService,
    required this.browserService,
    required this.shellService,
    required this.settingsService,
  });

  @override
  State<DevinWorkspaceScreen> createState() => _DevinWorkspaceScreenState();
}

class _DevinWorkspaceScreenState extends State<DevinWorkspaceScreen> with SingleTickerProviderStateMixin {
  final _taskController = TextEditingController();
  final _repoController = TextEditingController();
  late TabController _tabController;

  DevinState _devinState = DevinState();
  BrowserState _browserState = BrowserState();

  StreamSubscription<DevinState>? _agentSub;
  StreamSubscription<BrowserState>? _browserSub;

  final List<String> _sampleTasks = [
    'Fix NullPointerException in auth service and add regression tests',
    'Build a markdown to HTML converter with unit tests and open PR',
    'Refactor database connection pool and verify zero test regressions',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initDefaults();

    _agentSub = widget.agentService.onStateChanged.listen((s) {
      if (mounted) {
        setState(() => _devinState = s);
        // Auto-switch tabs based on current phase
        if (s.status == DevinRunStatus.testing) {
          _tabController.animateTo(1); // Shell & Tests tab
        } else if (s.status == DevinRunStatus.openingPr || s.status == DevinRunStatus.completed) {
          _tabController.animateTo(3); // PR tab
        }
      }
    });

    _browserSub = widget.browserService.onBrowserUpdated.listen((b) {
      if (mounted) {
        setState(() => _browserState = b);
      }
    });
  }

  Future<void> _initDefaults() async {
    final defaultRepo = await widget.settingsService.getDefaultRepoPath();
    final cwd = Directory.current.path;
    _repoController.text = (defaultRepo != null && defaultRepo.isNotEmpty) ? defaultRepo : cwd;
  }

  @override
  void dispose() {
    _agentSub?.cancel();
    _browserSub?.cancel();
    _taskController.dispose();
    _repoController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _runTask() {
    final task = _taskController.text.trim();
    final repo = _repoController.text.trim();
    if (task.isEmpty || repo.isEmpty) return;

    widget.agentService.runTask(taskPrompt: task, repoPath: repo);
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (ctx) => SettingsDialog(settingsService: widget.settingsService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _devinState.status != DevinRunStatus.idle &&
        _devinState.status != DevinRunStatus.completed &&
        _devinState.status != DevinRunStatus.failed;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161922),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.cyanAccent, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Devin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'AI Software Engineer',
                style: TextStyle(fontSize: 11, color: Colors.cyanAccent, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: 'Devin Tokens & Settings',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Top Task Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: const Color(0xFF161922),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _taskController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Describe an issue, bug, or feature for Devin to solve...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                          prefixIcon: const Icon(Icons.code, size: 18, color: Colors.cyanAccent),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0F1117),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _repoController,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          hintText: 'Repository Path',
                          prefixIcon: const Icon(Icons.folder, size: 18, color: Colors.amberAccent),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0F1117),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBusy ? Colors.redAccent : Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isBusy ? () => widget.agentService.stop() : _runTask,
                      icon: isBusy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.play_arrow, size: 18),
                      label: Text(
                        isBusy ? 'Stop' : 'Run Devin',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: _sampleTasks.map((task) {
                    return ActionChip(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                      label: Text(
                        task.length > 55 ? '${task.substring(0, 52)}...' : task,
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                      onPressed: () => _taskController.text = task,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),

          // Main Workspace Body: Split View
          Expanded(
            child: Row(
              children: [
                // Left Panel: Dynamic Step Checklist & Status
                Container(
                  width: 360,
                  decoration: const BoxDecoration(
                    color: Color(0xFF13151D),
                    border: Border(right: BorderSide(color: Colors.white10)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: const Color(0xFF181B24),
                        child: Row(
                          children: [
                            _buildStatusBadge(_devinState.status),
                            const Spacer(),
                            Text(
                              '${_devinState.plan.where((p) => p.status == PlanItemStatus.completed).length}/${_devinState.plan.length} done',
                              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          _devinState.statusMessage,
                          style: const TextStyle(fontSize: 12, color: Colors.cyanAccent),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      Expanded(
                        child: _devinState.plan.isEmpty
                            ? const Center(
                                child: Text('No active plan formulated yet.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _devinState.plan.length,
                                itemBuilder: (context, index) {
                                  final item = _devinState.plan[index];
                                  final isCurrent = index == _devinState.currentStepIndex &&
                                      item.status == PlanItemStatus.inProgress;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? Colors.cyanAccent.withValues(alpha: 0.1)
                                          : const Color(0xFF1C1F2B),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isCurrent
                                            ? Colors.cyanAccent
                                            : Colors.white.withValues(alpha: 0.05),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildStepStatusIcon(item.status),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                // Right Panel: Tabs for Plan, Shell, Browser, PR
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        color: const Color(0xFF161922),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.cyanAccent,
                          labelColor: Colors.cyanAccent,
                          unselectedLabelColor: Colors.grey,
                          tabs: const [
                            Tab(icon: Icon(Icons.playlist_add_check, size: 18), text: 'Plan Details'),
                            Tab(icon: Icon(Icons.terminal, size: 18), text: 'Shell & Tests'),
                            Tab(icon: Icon(Icons.public, size: 18), text: 'Browser'),
                            Tab(icon: Icon(Icons.merge_type, size: 18), text: 'Pull Request'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            PlanView(
                              plan: _devinState.plan,
                              currentStepIndex: _devinState.currentStepIndex,
                            ),
                            ShellView(
                              outputStream: widget.shellService.onOutput,
                              initialHistory: widget.shellService.history,
                              onClear: () => widget.shellService.clear(),
                            ),
                            BrowserView(
                              browserState: _browserState,
                              onNavigate: (url) => widget.browserService.openAndRead(url),
                            ),
                            PrView(pullRequest: _devinState.pullRequest),
                          ],
                        ),
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

  Widget _buildStatusBadge(DevinRunStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case DevinRunStatus.idle:
        color = Colors.grey;
        label = 'IDLE';
        icon = Icons.pause_circle_outline;
        break;
      case DevinRunStatus.planning:
        color = Colors.purpleAccent;
        label = 'PLANNING';
        icon = Icons.auto_awesome;
        break;
      case DevinRunStatus.running:
        color = Colors.cyanAccent;
        label = 'AUTONOMOUS RUN';
        icon = Icons.play_circle_fill;
        break;
      case DevinRunStatus.testing:
        color = Colors.amberAccent;
        label = 'EXECUTING TESTS';
        icon = Icons.fact_check;
        break;
      case DevinRunStatus.openingPr:
        color = Colors.blueAccent;
        label = 'OPENING PR';
        icon = Icons.fork_right;
        break;
      case DevinRunStatus.completed:
        color = Colors.greenAccent;
        label = 'COMPLETED';
        icon = Icons.check_circle;
        break;
      case DevinRunStatus.failed:
        color = Colors.redAccent;
        label = 'FAILED';
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStepStatusIcon(PlanItemStatus status) {
    switch (status) {
      case PlanItemStatus.pending:
        return const Icon(Icons.circle_outlined, size: 14, color: Colors.grey);
      case PlanItemStatus.inProgress:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
        );
      case PlanItemStatus.completed:
        return const Icon(Icons.check_circle, size: 14, color: Colors.greenAccent);
      case PlanItemStatus.failed:
        return const Icon(Icons.cancel, size: 14, color: Colors.redAccent);
    }
  }
}
