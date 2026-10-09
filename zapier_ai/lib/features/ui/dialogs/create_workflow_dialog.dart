import 'package:flutter/material.dart';
import '../../generator/workflow_generator_service.dart';
import '../../workflows/models/workflow.dart';

class CreateWorkflowDialog extends StatefulWidget {
  final WorkflowGeneratorService generatorService;

  const CreateWorkflowDialog({super.key, required this.generatorService});

  @override
  State<CreateWorkflowDialog> createState() => _CreateWorkflowDialogState();
}

class _CreateWorkflowDialogState extends State<CreateWorkflowDialog> {
  final _promptController = TextEditingController();
  bool _isGenerating = false;
  Workflow? _generatedWorkflow;
  String? _error;

  final List<String> _examplePrompts = [
    'When I get an email from customer support, summarize it with AI and post to Discord',
    'Every 60s fetch Bitcoin price from CoinGecko, analyze with AI, and send Slack alert',
    'Daily schedule: fetch weather forecast API, synthesize morning briefing with AI, and send email digest',
  ];

  Future<void> _generate() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final wf = await widget.generatorService.generateFromPrompt(text);
      if (mounted) {
        setState(() {
          _generatedWorkflow = wf;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to generate workflow: $e';
          _isGenerating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Create Zap with AI',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Describe what you want to automate in plain English. Zapier AI will generate the triggers, service connectors, actions, and data mappings.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _promptController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. When I get an email from X, summarize it and post to Discord...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _examplePrompts.map((p) {
                  return ActionChip(
                    label: Text(
                      p.length > 40 ? '${p.substring(0, 38)}...' : p,
                      style: const TextStyle(fontSize: 11),
                    ),
                    onPressed: () {
                      _promptController.text = p;
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (_isGenerating)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Colors.orange),
                        SizedBox(height: 12),
                        Text('Designing workflow steps & data mappings...'),
                      ],
                    ),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              if (_generatedWorkflow != null && !_isGenerating) ...[
                const Divider(height: 24),
                Text(
                  _generatedWorkflow!.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                Text(
                  _generatedWorkflow!.description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                const Text('Generated Steps:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildStepPreview('Trigger', _generatedWorkflow!.trigger.name, _generatedWorkflow!.trigger.service, Colors.green),
                ..._generatedWorkflow!.actions.asMap().entries.map((entry) {
                  return _buildStepPreview(
                    'Step ${entry.key + 1}',
                    entry.value.name,
                    entry.value.service,
                    Colors.blue,
                  );
                }),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  if (_generatedWorkflow == null)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isGenerating ? null : _generate,
                      icon: const Icon(Icons.bolt, size: 18),
                      label: const Text('Generate Workflow'),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(_generatedWorkflow),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Add & Activate Zap'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepPreview(String label, String name, String service, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
          Text(
            service.toUpperCase(),
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
