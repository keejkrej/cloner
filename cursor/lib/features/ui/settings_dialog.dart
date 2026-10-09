import 'package:flutter/material.dart';
import '../../core/settings/settings_service.dart';

class SettingsDialog extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsDialog({super.key, required this.settingsService});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _chatModelController;
  late TextEditingController _fimModelController;
  late TextEditingController _embeddingModelController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.settingsService.apiKey);
    _baseUrlController = TextEditingController(text: widget.settingsService.baseUrl);
    _chatModelController = TextEditingController(text: widget.settingsService.chatModel);
    _fimModelController = TextEditingController(text: widget.settingsService.fimModel);
    _embeddingModelController = TextEditingController(text: widget.settingsService.embeddingModel);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _chatModelController.dispose();
    _fimModelController.dispose();
    _embeddingModelController.dispose();
    super.dispose();
  }

  void _save() {
    widget.settingsService.saveSettings(
      apiKey: _apiKeyController.text,
      baseUrl: _baseUrlController.text,
      chatModel: _chatModelController.text,
      fimModel: _fimModelController.text,
      embeddingModel: _embeddingModelController.text,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
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
                  const Text('Cursor AI Configuration', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                  filled: true,
                  fillColor: Color(0xFF282828),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _baseUrlController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                  filled: true,
                  fillColor: Color(0xFF282828),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatModelController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Chat & Edit Model',
                        labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                        filled: true,
                        fillColor: Color(0xFF282828),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _fimModelController,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Fast FIM Autocomplete Model',
                        labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                        filled: true,
                        fillColor: Color(0xFF282828),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                ],
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007ACC),
                      foregroundColor: Colors.white,
                    ),
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
