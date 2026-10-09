import 'package:flutter/material.dart';
import '../../core/diff/diff_service.dart';

class ApprovalDialog extends StatelessWidget {
  final String toolName;
  final String target;
  final String details;
  final List<DiffLine>? diffLines;

  const ApprovalDialog({
    super.key,
    required this.toolName,
    required this.target,
    required this.details,
    this.diffLines,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    toolName == 'run_command' ? Icons.terminal : Icons.edit_document,
                    color: const Color(0xFFDA7756),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Permission Request: $toolName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Target: $target',
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Consolas'),
              ),
              const SizedBox(height: 8),

              if (diffLines != null && diffLines!.isNotEmpty) ...[
                const Text('Proposed changes:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: ListView.builder(
                      itemCount: diffLines!.length,
                      itemBuilder: (context, i) {
                        final line = diffLines![i];
                        final isAdd = line.type == '+';
                        final isDel = line.type == '-';

                        return Container(
                          color: isAdd
                              ? Colors.green.withValues(alpha: 0.15)
                              : isDel
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : Colors.transparent,
                          child: Text(
                            '${line.type} ${line.text}',
                            style: TextStyle(
                              fontFamily: 'Consolas',
                              fontSize: 12,
                              color: isAdd
                                  ? Colors.greenAccent
                                  : isDel
                                      ? Colors.redAccent
                                      : Colors.white70,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SelectableText(
                    details,
                    style: const TextStyle(fontFamily: 'Consolas', color: Colors.white, fontSize: 13),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Deny'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDA7756),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Approve & Execute'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
