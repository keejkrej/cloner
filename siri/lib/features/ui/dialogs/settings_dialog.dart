import 'package:flutter/material.dart';
import '../../../core/settings/settings_service.dart';

class SettingsDialog extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsDialog({super.key, required this.settingsService});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _openAiController = TextEditingController();
  String _selectedVoice = 'nova';
  bool _wakeWordEnabled = true;
  bool _loading = true;

  final List<String> _voices = ['nova', 'alloy', 'echo', 'shimmer', 'onyx', 'fable'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final key = await widget.settingsService.getOpenAiKey();
    final voice = await widget.settingsService.getTtsVoice();
    final wakeEnabled = await widget.settingsService.isWakeWordEnabled();

    if (mounted) {
      setState(() {
        _openAiController.text = key ?? '';
        _selectedVoice = voice;
        _wakeWordEnabled = wakeEnabled;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    await widget.settingsService.setOpenAiKey(_openAiController.text.trim());
    await widget.settingsService.setTtsVoice(_selectedVoice);
    await widget.settingsService.setWakeWordEnabled(_wakeWordEnabled);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Siri settings saved successfully')),
      );
    }
  }

  @override
  void dispose() {
    _openAiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C28),
      title: const Row(
        children: [
          Icon(Icons.settings_voice, color: Color(0xFF00E5FF)),
          SizedBox(width: 10),
          Text('Siri Preferences', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: _loading
          ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
          : SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure API keys for OpenAI Whisper STT, GPT-4o tool calling, and high-fidelity TTS voice. If left blank, Siri uses local offline tools and Windows speech synthesis.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _openAiController,
                    decoration: const InputDecoration(
                      labelText: 'OpenAI API Key (sk-...)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedVoice,
                    decoration: const InputDecoration(
                      labelText: 'TTS Spoken Voice',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.record_voice_over),
                    ),
                    dropdownColor: const Color(0xFF252538),
                    items: _voices.map((v) {
                      return DropdownMenuItem(value: v, child: Text(v.toUpperCase()));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedVoice = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Background Wake Word ("Hey Siri")', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Low CPU idle listener activates overlay on keyword', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: _wakeWordEnabled,
                    activeThumbColor: const Color(0xFF00E5FF),
                    onChanged: (val) => setState(() => _wakeWordEnabled = val),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E5FF),
            foregroundColor: Colors.black,
          ),
          onPressed: _save,
          child: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
