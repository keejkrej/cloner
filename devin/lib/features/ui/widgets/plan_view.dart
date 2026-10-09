import 'package:flutter/material.dart';
import '../../planner/models/plan_item.dart';

class PlanView extends StatelessWidget {
  final List<PlanItem> plan;
  final int currentStepIndex;

  const PlanView({
    super.key,
    required this.plan,
    required this.currentStepIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (plan.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist, size: 54, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            const Text(
              'No active task plan yet',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter an issue or feature prompt above and click "Run Devin"',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: plan.length,
      itemBuilder: (context, index) {
        final item = plan[index];
        return _buildPlanCard(context, item, index);
      },
    );
  }

  Widget _buildPlanCard(BuildContext context, PlanItem item, int index) {
    Color statusColor;
    Widget statusIcon;

    switch (item.status) {
      case PlanItemStatus.pending:
        statusColor = Colors.grey;
        statusIcon = const Icon(Icons.radio_button_unchecked, size: 20, color: Colors.grey);
        break;
      case PlanItemStatus.inProgress:
        statusColor = Colors.cyanAccent;
        statusIcon = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
        );
        break;
      case PlanItemStatus.completed:
        statusColor = Colors.greenAccent;
        statusIcon = const Icon(Icons.check_circle, size: 20, color: Colors.greenAccent);
        break;
      case PlanItemStatus.failed:
        statusColor = Colors.redAccent;
        statusIcon = const Icon(Icons.cancel, size: 20, color: Colors.redAccent);
        break;
    }

    final isCurrent = index == currentStepIndex && item.status == PlanItemStatus.inProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFF1E2638)
            : const Color(0xFF161922),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? Colors.cyanAccent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                statusIcon,
                const SizedBox(width: 12),
                Text(
                  'Step ${index + 1}: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                ),
                if (item.tool != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.tool!,
                      style: const TextStyle(fontSize: 10, color: Colors.cyanAccent, fontFamily: 'monospace'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                item.description,
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
            if (item.output != null) ...[
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.only(left: 32),
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Text(
                  item.output!,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.greenAccent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
