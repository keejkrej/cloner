import 'dart:convert';
import 'package:http/http.dart' as http;
import '../settings/settings_service.dart';

class PromptEnhancer {
  final SettingsService settingsService;

  PromptEnhancer({required this.settingsService});

  Future<String> enhancePrompt({
    required String rawPrompt,
    required String aspectRatio,
  }) async {
    final clean = rawPrompt.trim();
    if (clean.isEmpty) return '';

    if (!settingsService.hasLlmKey) {
      // Local enhancement template fallback if no key
      return '$clean, cinematic lighting, ultra-detailed 8k resolution, photorealistic, intricate textures, volumetric atmosphere, octane render --ar $aspectRatio';
    }

    final client = http.Client();
    try {
      var baseUrl = settingsService.llmBaseUrl.trim();
      if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);

      final response = await client.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settingsService.llmApiKey}',
        },
        body: jsonEncode({
          'model': settingsService.llmModel,
          'messages': [
            {
              'role': 'system',
              'content': '''You are the master Midjourney v6 Prompt Enhancer.
Your goal is to expand simple, lazy user descriptions into richly detailed, visually breathtaking Midjourney prompts.
Instructions:
- Describe the subject, composition, cinematic lighting (e.g. rim lighting, golden hour, volumetric god rays), textures, camera optics (e.g. 35mm lens, f/1.8, shallow depth of field), and overall aesthetic atmosphere.
- Avoid buzzwords like "hyperrealistic"; use concrete photographic and artistic descriptors.
- Append "--ar $aspectRatio" at the very end.
- Output ONLY the expanded prompt string with no commentary or quotes.''',
            },
            {'role': 'user', 'content': clean},
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final enhanced = json['choices']?[0]?['message']?['content'] as String?;
        if (enhanced != null && enhanced.trim().isNotEmpty) {
          return enhanced.trim();
        }
      }
    } catch (_) {} finally {
      client.close();
    }

    return '$clean, cinematic lighting, 8k resolution, volumetric atmospheric depth, intricate textures --ar $aspectRatio';
  }
}
