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
  final _githubTokenController = TextEditingController();
  final _defaultRepoController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final key = await widget.settingsService.getOpenAiKey();
    final token = await widget.settingsService.getGithubToken();
    final repo = await widget.settingsService.getDefaultRepoPath();

    if (mounted) {
      setState(() {
        _openAiController.text = key ?? '';
        _githubTokenController.text = token ?? '';
        _defaultRepoController.text = repo ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    await widget.settingsService.setOpenAiKey(_openAiController.text.trim());
    await widget.settingsService.setGithubToken(_githubTokenController.text.trim());
    await widget.settingsService.setDefaultRepoPath(_defaultRepoController.text.trim());
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devin configuration saved')),
      );
    }
  }

  @override
  void dispose() {
    _openAiController.dispose();
    _githubTokenController.dispose();
    _defaultRepoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF161922),
      title: const Row(
        children: [
          Icon(Icons.smart_toy, color: Colors.cyanAccent),
          SizedBox(width: 10),
          Text('Devin Settings & Tokens', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: _loading
          ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
          : SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Configure API keys and GitHub tokens for automated branch creation, testing, and PR submission.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _openAiController,
                    decoration: const InputDecoration(
                      labelText: 'OpenAI API Key (sk-...)',
                      hintText: 'Coding LLM for planning and code iteration',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.psychology),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _githubTokenController,
                    decoration: const InputDecoration(
                      labelText: 'GitHub Token (ghp_...)',
                      hintText: 'Used by PR Bot to open pull requests',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.token),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _defaultRepoController,
                    decoration: const InputDecoration(
                      labelText: 'Default Repository Path',
                      hintText: 'C:\\Users\\...\\workspace\\project',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.folder_open),
                    ),
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
          onPressed: _save,
          child: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
