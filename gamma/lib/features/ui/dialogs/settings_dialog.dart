import 'package:flutter/material.dart';
import '../../../core/settings/settings_service.dart';

class SettingsDialog extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsDialog({super.key, required this.settingsService});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.settingsService.apiKey);
    _baseUrlController = TextEditingController(text: widget.settingsService.baseUrl);
    _modelController = TextEditingController(text: widget.settingsService.model);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.settingsService.setApiKey(_apiKeyController.text);
    await widget.settingsService.setBaseUrl(_baseUrlController.text);
    await widget.settingsService.setModel(_modelController.text);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings, color: Colors.amberAccent),
          SizedBox(width: 8),
          Text('Gamma AI Settings'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OpenRouter / OpenAI API Key', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'sk-or-... or sk-...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  helperText: 'Powers outline generation and structured slide deck composition',
                ),
              ),
              const SizedBox(height: 16),
              const Text('API Base URL', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  hintText: 'https://openrouter.ai/api/v1',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Model', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  hintText: 'anthropic/claude-3.5-sonnet',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Offline Mode: If no API key is configured, Gamma uses a rich architectural generator with all 6 layouts and themes ready for immediate presentation.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save Settings'),
        ),
      ],
    );
  }
}
