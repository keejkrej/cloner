import 'package:flutter/material.dart';
import '../../workflows/models/workflow.dart';
import '../../workflows/models/workflow_step.dart';

class StepFlowView extends StatelessWidget {
  final Workflow workflow;
  final VoidCallback onRunNow;
  final bool isRunning;

  const StepFlowView({
    super.key,
    required this.workflow,
    required this.onRunNow,
    this.isRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workflow.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workflow.description,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: isRunning ? null : onRunNow,
                icon: isRunning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow, size: 20),
                label: Text(isRunning ? 'Executing...' : 'Run Zap Now'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'WORKFLOW PIPELINE',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          _buildStepCard(
            context: context,
            stepIndex: 1,
            step: workflow.trigger,
            isTrigger: true,
          ),
          ...workflow.actions.asMap().entries.map((entry) {
            final idx = entry.key + 2;
            final action = entry.value;
            return Column(
              children: [
                _buildFlowConnector(),
                _buildStepCard(
                  context: context,
                  stepIndex: idx,
                  step: action,
                  isTrigger: false,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFlowConnector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Container(width: 2, height: 16, color: Colors.orange.withValues(alpha: 0.5)),
          const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required BuildContext context,
    required int stepIndex,
    required WorkflowStep step,
    required bool isTrigger,
  }) {
    final theme = Theme.of(context);
    final accentColor = isTrigger ? Colors.teal : _getServiceColor(step.service);
    final icon = _getServiceIcon(step.service);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isTrigger ? '1. TRIGGER' : '$stepIndex. ACTION',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    step.service.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Event: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(step.actionName, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                if (step.inputMappings.isNotEmpty) ...[
                  const Text('Input Variable Mappings:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: step.inputMappings.entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${e.key} ➔ ${e.value}',
                          style: const TextStyle(fontSize: 11, color: Colors.orange, fontFamily: 'monospace'),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                const Text('Configuration:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: step.config.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color),
                            children: [
                              TextSpan(text: '${entry.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: '${entry.value}', style: const TextStyle(fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getServiceColor(String service) {
    switch (service) {
      case 'schedule':
        return Colors.teal;
      case 'http':
        return Colors.blue;
      case 'ai':
        return Colors.purple;
      case 'discord':
        return const Color(0xFF5865F2);
      case 'slack':
        return const Color(0xFF4A154B);
      case 'email':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  IconData _getServiceIcon(String service) {
    switch (service) {
      case 'schedule':
        return Icons.timer_outlined;
      case 'http':
        return Icons.http;
      case 'ai':
        return Icons.auto_awesome;
      case 'discord':
        return Icons.forum;
      case 'slack':
        return Icons.chat;
      case 'email':
        return Icons.email_outlined;
      default:
        return Icons.extension;
    }
  }
}
