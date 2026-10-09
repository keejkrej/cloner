import 'package:flutter/material.dart';
import '../../core/settings/settings_service.dart';

class SettingsDialog extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsDialog({super.key, required this.settingsService});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _llmApiKeyController;
  late TextEditingController _llmBaseUrlController;
  late TextEditingController _llmModelController;
  late TextEditingController _ttsApiKeyController;
  late TextEditingController _sttApiKeyController;
  late bool _autoPlayVoice;

  @override
  void initState() {
    super.initState();
    _llmApiKeyController = TextEditingController(text: widget.settingsService.llmApiKey);
    _llmBaseUrlController = TextEditingController(text: widget.settingsService.llmBaseUrl);
    _llmModelController = TextEditingController(text: widget.settingsService.llmModel);
    _ttsApiKeyController = TextEditingController(text: widget.settingsService.ttsApiKey);
    _sttApiKeyController = TextEditingController(text: widget.settingsService.sttApiKey);
    _autoPlayVoice = widget.settingsService.autoPlayVoice;
  }

  @override
  void dispose() {
    _llmApiKeyController.dispose();
    _llmBaseUrlController.dispose();
    _llmModelController.dispose();
    _ttsApiKeyController.dispose();
    _sttApiKeyController.dispose();
    super.dispose();
  }

  void _save() {
    widget.settingsService.saveSettings(
      llmApiKey: _llmApiKeyController.text,
      llmBaseUrl: _llmBaseUrlController.text,
      llmModel: _llmModelController.text,
      ttsApiKey: _ttsApiKeyController.text,
      sttApiKey: _sttApiKeyController.text,
      autoPlayVoice: _autoPlayVoice,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1F22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Character AI Settings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _llmApiKeyController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'LLM API Key (OpenAI / OpenRouter)',
                  labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                  filled: true,
                  fillColor: Color(0xFF2B2D31),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _llmBaseUrlController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Base URL',
                        labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                        filled: true,
                        fillColor: Color(0xFF2B2D31),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _llmModelController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                        filled: true,
                        fillColor: Color(0xFF2B2D31),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto-play character speech', style: TextStyle(color: Colors.white, fontSize: 12)),
                subtitle: const Text('Spoken replies automatically play when received', style: TextStyle(color: Colors.white54, fontSize: 10)),
                value: _autoPlayVoice,
                activeTrackColor: const Color(0xFF5865F2),
                onChanged: (val) => setState(() => _autoPlayVoice = val),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5865F2), foregroundColor: Colors.white),
                    onPressed: _save,
                    child: const Text('Save Settings'),
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
