import 'dart:convert';
import 'package:flutter/material.dart';
import '../../workflows/models/workflow_run.dart';

class RunHistoryView extends StatelessWidget {
  final List<WorkflowRun> runs;
  final VoidCallback onRefresh;

  const RunHistoryView({
    super.key,
    required this.runs,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (runs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            const Text('No runs recorded yet', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: runs.length,
      itemBuilder: (context, index) {
        final run = runs[index];
        final isSuccess = run.status == 'success';
        final isRunning = run.status == 'running';
        final color = isRunning
            ? Colors.amber
            : (isSuccess ? Colors.green : Colors.red);

        final duration = run.finishedAt != null
            ? '${run.finishedAt!.difference(run.startedAt).inMilliseconds}ms'
            : 'running...';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: color.withValues(alpha: 0.3)),
          ),
          child: ExpansionTile(
            leading: Icon(
              isRunning
                  ? Icons.hourglass_top
                  : (isSuccess ? Icons.check_circle : Icons.error),
              color: color,
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    run.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    run.workflowTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'Started: ${run.startedAt.toLocal().toString().split('.').first} • Duration: $duration',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trigger Payload:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        jsonEncode(run.triggerPayload),
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Step Execution Logs:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    ...run.stepLogs.map((log) => _buildStepLogTile(context, log)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepLogTile(BuildContext context, StepExecutionLog log) {
    final ok = log.status == 'success';
    final statusColor = ok ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ok ? Icons.check_circle_outline : Icons.highlight_off, size: 16, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  log.stepName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Text(
                log.service.toUpperCase(),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (log.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              'Error: ${log.errorMessage}',
              style: const TextStyle(fontSize: 11, color: Colors.red),
            ),
          ],
          const SizedBox(height: 6),
          const Text('Outputs:', style: TextStyle(fontSize: 10, color: Colors.grey)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              jsonEncode(log.outputs),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
