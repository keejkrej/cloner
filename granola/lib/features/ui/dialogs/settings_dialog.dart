import 'package:flutter/material.dart';
import '../../../core/settings/settings_service.dart';

class SettingsDialog extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsDialog({super.key, required this.settingsService});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late final TextEditingController _deepgramKeyController;
  late final TextEditingController _llmKeyController;
  late final TextEditingController _llmBaseUrlController;
  late final TextEditingController _llmModelController;

  @override
  void initState() {
    super.initState();
    _deepgramKeyController = TextEditingController(text: widget.settingsService.deepgramApiKey);
    _llmKeyController = TextEditingController(text: widget.settingsService.llmApiKey);
    _llmBaseUrlController = TextEditingController(text: widget.settingsService.llmBaseUrl);
    _llmModelController = TextEditingController(text: widget.settingsService.llmModel);
  }

  @override
  void dispose() {
    _deepgramKeyController.dispose();
    _llmKeyController.dispose();
    _llmBaseUrlController.dispose();
    _llmModelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.settingsService.setDeepgramApiKey(_deepgramKeyController.text);
    await widget.settingsService.setLlmApiKey(_llmKeyController.text);
    await widget.settingsService.setLlmBaseUrl(_llmBaseUrlController.text);
    await widget.settingsService.setLlmModel(_llmModelController.text);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings, color: Colors.tealAccent),
          SizedBox(width: 8),
          Text('Granola Settings'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Deepgram API Key (Live Diarized STT)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _deepgramKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Deepgram token...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  helperText: 'Powers live speech-to-text with real-time speaker separation',
                ),
              ),
              const SizedBox(height: 16),
              const Text('LLM API Key (Note Enhancement)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _llmKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'sk-or-... or sk-...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  helperText: 'Merges rough notes with transcript into executive minutes',
                ),
              ),
              const SizedBox(height: 16),
              const Text('LLM Base URL', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _llmBaseUrlController,
                decoration: const InputDecoration(
                  hintText: 'https://openrouter.ai/api/v1',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text('LLM Model', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _llmModelController,
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
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Offline Demo: If no API keys are configured, Granola runs a multi-speaker diarized meeting simulation and structured note synthesizer for instant zero-config testing.',
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
