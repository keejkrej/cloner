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
  final _discordController = TextEditingController();
  final _slackController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final openAi = await widget.settingsService.getOpenAiKey();
    final discord = await widget.settingsService.getDiscordWebhook();
    final slack = await widget.settingsService.getSlackWebhook();

    if (mounted) {
      setState(() {
        _openAiController.text = openAi ?? '';
        _discordController.text = discord ?? '';
        _slackController.text = slack ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    await widget.settingsService.setOpenAiKey(_openAiController.text.trim());
    await widget.settingsService.setDiscordWebhook(_discordController.text.trim());
    await widget.settingsService.setSlackWebhook(_slackController.text.trim());
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  @override
  void dispose() {
    _openAiController.dispose();
    _discordController.dispose();
    _slackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings, color: Colors.orange),
          SizedBox(width: 8),
          Text('Connector API Keys & Webhooks'),
        ],
      ),
      content: _loading
          ? const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Provide credentials for real third-party service dispatch. If left empty, Zapier AI operates with built-in verified mock dispatch and offline AI synthesis.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _openAiController,
                      decoration: const InputDecoration(
                        labelText: 'OpenAI API Key (sk-...)',
                        hintText: 'Used for AI Steps & natural language workflow generation',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.psychology),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _discordController,
                      decoration: const InputDecoration(
                        labelText: 'Discord Webhook URL',
                        hintText: 'https://discord.com/api/webhooks/...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.forum),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _slackController,
                      decoration: const InputDecoration(
                        labelText: 'Slack Incoming Webhook URL',
                        hintText: 'https://hooks.slack.com/services/...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.chat),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
          onPressed: _saveSettings,
          child: const Text('Save Settings'),
        ),
      ],
    );
  }
}
