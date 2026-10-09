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
  late TextEditingController _imageApiKeyController;
  late String _imageProvider;

  @override
  void initState() {
    super.initState();
    _llmApiKeyController = TextEditingController(text: widget.settingsService.llmApiKey);
    _llmBaseUrlController = TextEditingController(text: widget.settingsService.llmBaseUrl);
    _llmModelController = TextEditingController(text: widget.settingsService.llmModel);
    _imageApiKeyController = TextEditingController(text: widget.settingsService.imageApiKey);
    _imageProvider = widget.settingsService.imageProvider;
  }

  @override
  void dispose() {
    _llmApiKeyController.dispose();
    _llmBaseUrlController.dispose();
    _llmModelController.dispose();
    _imageApiKeyController.dispose();
    super.dispose();
  }

  void _save() {
    widget.settingsService.saveSettings(
      llmApiKey: _llmApiKeyController.text,
      llmBaseUrl: _llmBaseUrlController.text,
      llmModel: _llmModelController.text,
      imageApiKey: _imageApiKeyController.text,
      imageProvider: _imageProvider,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF181A20),
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
                  const Text('Midjourney Settings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('1. Prompt Enhancer LLM', style: TextStyle(color: Color(0xFF8AB4F8), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _llmApiKeyController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'LLM API Key (OpenAI / OpenRouter)',
                  labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                  filled: true,
                  fillColor: Color(0xFF222630),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 14),
              const Text('2. Diffusion Generator', style: TextStyle(color: Color(0xFF8AB4F8), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: const Color(0xFF222630), borderRadius: BorderRadius.circular(6)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _imageProvider,
                        dropdownColor: const Color(0xFF222630),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        items: const [
                          DropdownMenuItem(value: 'pollinations', child: Text('Flux / SDXL (Pollinations Free)')),
                          DropdownMenuItem(value: 'dalle', child: Text('OpenAI DALL-E 3')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _imageProvider = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_imageProvider == 'dalle')
                    Expanded(
                      child: TextField(
                        controller: _imageApiKeyController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Image API Key',
                          labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                          filled: true,
                          fillColor: Color(0xFF222630),
                          border: OutlineInputBorder(borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2463EB), foregroundColor: Colors.white),
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
