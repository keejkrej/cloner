import 'package:flutter/material.dart';
import '../../workflows/models/workflow.dart';

class WorkflowCard extends StatelessWidget {
  final Workflow workflow;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onRunNow;
  final VoidCallback onDelete;

  const WorkflowCard({
    super.key,
    required this.workflow,
    required this.isSelected,
    required this.onTap,
    required this.onToggleActive,
    required this.onRunNow,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isSelected ? Colors.orange : theme.dividerColor.withValues(alpha: 0.3);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withValues(alpha: 0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    workflow.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? Colors.orange.shade300 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Switch(
                  value: workflow.isActive,
                  activeThumbColor: Colors.orange,
                  onChanged: onToggleActive,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              workflow.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${workflow.actions.length + 1} steps',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    workflow.trigger.service.toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.play_arrow, size: 18, color: Colors.green),
                  tooltip: 'Run Zap Now',
                  onPressed: onRunNow,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                  tooltip: 'Delete Zap',
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
