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
  late TextEditingController _searchApiKeyController;
  late String _searchProvider;
  late TextEditingController _rerankApiKeyController;
  late String _rerankProvider;

  @override
  void initState() {
    super.initState();
    _llmApiKeyController = TextEditingController(text: widget.settingsService.llmApiKey);
    _llmBaseUrlController = TextEditingController(text: widget.settingsService.llmBaseUrl);
    _llmModelController = TextEditingController(text: widget.settingsService.llmModel);
    _searchApiKeyController = TextEditingController(text: widget.settingsService.searchApiKey);
    _searchProvider = widget.settingsService.searchProvider;
    _rerankApiKeyController = TextEditingController(text: widget.settingsService.rerankApiKey);
    _rerankProvider = widget.settingsService.rerankProvider;
  }

  @override
  void dispose() {
    _llmApiKeyController.dispose();
    _llmBaseUrlController.dispose();
    _llmModelController.dispose();
    _searchApiKeyController.dispose();
    _rerankApiKeyController.dispose();
    super.dispose();
  }

  void _save() {
    widget.settingsService.saveSettings(
      llmApiKey: _llmApiKeyController.text,
      llmBaseUrl: _llmBaseUrlController.text,
      llmModel: _llmModelController.text,
      searchApiKey: _searchApiKeyController.text,
      searchProvider: _searchProvider,
      rerankApiKey: _rerankApiKeyController.text,
      rerankProvider: _rerankProvider,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF191E24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Perplexity Engine Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // LLM Section
              const Text('1. LLM Synthesizer', style: TextStyle(color: Color(0xFF20B8CD), fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _llmApiKeyController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'LLM API Key',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF20262E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _llmBaseUrlController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Base URL',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: const Color(0xFF20262E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _llmModelController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Model',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: const Color(0xFF20262E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search Section
              const Text('2. Live Web Search Provider', style: TextStyle(color: Color(0xFF20B8CD), fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF20262E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _searchProvider,
                        dropdownColor: const Color(0xFF20262E),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: const [
                          DropdownMenuItem(value: 'tavily', child: Text('Tavily Search')),
                          DropdownMenuItem(value: 'brave', child: Text('Brave Search')),
                          DropdownMenuItem(value: 'serper', child: Text('Serper (Google)')),
                          DropdownMenuItem(value: 'duckduckgo', child: Text('DuckDuckGo (Built-in/Free)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _searchProvider = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchApiKeyController,
                      obscureText: true,
                      enabled: _searchProvider != 'duckduckgo',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: _searchProvider == 'duckduckgo' ? 'No key required' : 'Search API Key',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: const Color(0xFF20262E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Reranker Section
              const Text('3. Reranker', style: TextStyle(color: Color(0xFF20B8CD), fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF20262E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _rerankProvider,
                        dropdownColor: const Color(0xFF20262E),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: const [
                          DropdownMenuItem(value: 'local', child: Text('Local Cross-Scorer (Free)')),
                          DropdownMenuItem(value: 'cohere', child: Text('Cohere Rerank API')),
                          DropdownMenuItem(value: 'jina', child: Text('Jina Reranker API')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _rerankProvider = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _rerankApiKeyController,
                      obscureText: true,
                      enabled: _rerankProvider != 'local',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: _rerankProvider == 'local' ? 'Built-in relevance scoring' : 'Rerank API Key',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: const Color(0xFF20262E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF20B8CD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
