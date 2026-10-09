import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../settings/settings_service.dart';

class AutocompleteService extends ChangeNotifier {
  final SettingsService settingsService;
  Timer? _debounceTimer;
  String _ghostText = '';
  bool _isLoading = false;

  AutocompleteService({required this.settingsService});

  String get ghostText => _ghostText;
  bool get isLoading => _isLoading;

  void clearGhostText() {
    _debounceTimer?.cancel();
    if (_ghostText.isNotEmpty) {
      _ghostText = '';
      notifyListeners();
    }
  }

  void triggerAutocomplete({
    required String prefix,
    required String suffix,
    required String fileName,
  }) {
    _debounceTimer?.cancel();
    if (!settingsService.hasValidApiKey || prefix.trim().isEmpty) {
      _ghostText = '';
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await _fetchCompletion(prefix: prefix, suffix: suffix, fileName: fileName);
    });
  }

  Future<void> _fetchCompletion({
    required String prefix,
    required String suffix,
    required String fileName,
  }) async {
    _isLoading = true;
    notifyListeners();

    final client = http.Client();
    try {
      var baseUrl = settingsService.baseUrl.trim();
      if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);

      // Extract last 1000 characters of prefix and first 300 of suffix
      final cleanPrefix = prefix.length > 1000 ? prefix.substring(prefix.length - 1000) : prefix;
      final cleanSuffix = suffix.length > 300 ? suffix.substring(0, 300) : suffix;

      final prompt = '''You are a fast inline code autocomplete model (like Cursor / Copilot).
File: $fileName

Code before cursor:
```
$cleanPrefix
```

Code after cursor:
```
$cleanSuffix
```

Task:
Complete the code starting exactly from the cursor.
Output ONLY the raw code to be inserted directly at the cursor.
Do NOT use markdown backticks.
Do NOT repeat the prefix.
Keep the completion concise (1 to 4 lines).''';

      final response = await client.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settingsService.apiKey}',
        },
        body: jsonEncode({
          'model': settingsService.fimModel,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 64,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final raw = json['choices']?[0]?['message']?['content'] as String? ?? '';
        var cleanGhost = raw.replaceAll('```', '').trimRight();
        if (cleanGhost.startsWith('\n')) cleanGhost = cleanGhost.substring(1);

        _ghostText = cleanGhost;
      }
    } catch (_) {
      _ghostText = '';
    } finally {
      client.close();
      _isLoading = false;
      notifyListeners();
    }
  }
}
