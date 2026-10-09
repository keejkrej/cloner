import 'package:flutter/material.dart';
import '../../../core/settings/settings_service.dart';

class SettingsDialog extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsDialog({super.key, required this.settingsService});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late final TextEditingController _elevenLabsKeyController;
  late final TextEditingController _openAiKeyController;
  late String _selectedModel;

  final _models = [
    'eleven_multilingual_v2',
    'eleven_turbo_v2_5',
    'eleven_turbo_v2',
    'eleven_monolingual_v1',
  ];

  @override
  void initState() {
    super.initState();
    _elevenLabsKeyController = TextEditingController(
      text: widget.settingsService.elevenLabsApiKey,
    );
    _openAiKeyController = TextEditingController(
      text: widget.settingsService.openAiApiKey,
    );
    _selectedModel = widget.settingsService.modelId;
    if (!_models.contains(_selectedModel)) {
      _selectedModel = _models.first;
    }
  }

  @override
  void dispose() {
    _elevenLabsKeyController.dispose();
    _openAiKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.settingsService.setElevenLabsApiKey(_elevenLabsKeyController.text);
    await widget.settingsService.setOpenAiApiKey(_openAiKeyController.text);
    await widget.settingsService.setModelId(_selectedModel);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings, color: Colors.blueAccent),
          SizedBox(width: 8),
          Text('Settings & API Keys'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ElevenLabs API Key',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _elevenLabsKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'xi-...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  helperText: 'Primary API for high-quality speech and voice cloning',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Model',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedModel,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _models.map((m) {
                  return DropdownMenuItem(value: m, child: Text(m));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedModel = val);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'OpenAI API Key (Optional Fallback)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _openAiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'sk-...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  helperText: 'Used for fallback TTS if ElevenLabs key is unset',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Note: If no API key is supplied, a built-in synthesized voice simulator allows offline evaluation and testing without API limits.',
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
