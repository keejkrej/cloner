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
  late TextEditingController _ttsVoiceAController;
  late TextEditingController _ttsVoiceBController;

  @override
  void initState() {
    super.initState();
    _llmApiKeyController = TextEditingController(text: widget.settingsService.llmApiKey);
    _llmBaseUrlController = TextEditingController(text: widget.settingsService.llmBaseUrl);
    _llmModelController = TextEditingController(text: widget.settingsService.llmModel);
    _ttsApiKeyController = TextEditingController(text: widget.settingsService.ttsApiKey);
    _ttsVoiceAController = TextEditingController(text: widget.settingsService.ttsVoiceA);
    _ttsVoiceBController = TextEditingController(text: widget.settingsService.ttsVoiceB);
  }

  @override
  void dispose() {
    _llmApiKeyController.dispose();
    _llmBaseUrlController.dispose();
    _llmModelController.dispose();
    _ttsApiKeyController.dispose();
    _ttsVoiceAController.dispose();
    _ttsVoiceBController.dispose();
    super.dispose();
  }

  void _save() {
    widget.settingsService.saveSettings(
      llmApiKey: _llmApiKeyController.text,
      llmBaseUrl: _llmBaseUrlController.text,
      llmModel: _llmModelController.text,
      ttsApiKey: _ttsApiKeyController.text,
      ttsVoiceA: _ttsVoiceAController.text,
      ttsVoiceB: _ttsVoiceBController.text,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1B202E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('NotebookLM Settings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('LLM Provider (RAG & Script)', style: TextStyle(color: Color(0xFF6C8CFF), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _llmApiKeyController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'OpenAI / OpenRouter API Key',
                  labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                  filled: true,
                  fillColor: Color(0xFF141824),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 8),
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
                        fillColor: Color(0xFF141824),
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
                        fillColor: Color(0xFF141824),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Audio Overview TTS (Alex & Sam)', style: TextStyle(color: Color(0xFF6C8CFF), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ttsVoiceAController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Host 1 Voice (Alex)',
                        labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                        filled: true,
                        fillColor: Color(0xFF141824),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _ttsVoiceBController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Host 2 Voice (Sam)',
                        labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                        filled: true,
                        fillColor: Color(0xFF141824),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C8CFF), foregroundColor: Colors.white),
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
