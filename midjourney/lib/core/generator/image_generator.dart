import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../settings/settings_service.dart';

class ImageGenerator {
  final SettingsService settingsService;
  final _uuid = const Uuid();
  final _random = Random();

  ImageGenerator({required this.settingsService});

  /// Generates a grid of 4 images for the given prompt and returns their saved local file paths
  Future<List<String>> generateGrid4({
    required String prompt,
    required String aspectRatio,
    void Function(int current, int total)? onProgress,
  }) async {
    final appDocs = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDocs.path, 'MidjourneyClone', 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final (width, height) = _dimensionsForAspectRatio(aspectRatio);
    final savedPaths = <String>[];

    final client = http.Client();
    try {
      for (int i = 0; i < 4; i++) {
        onProgress?.call(i + 1, 4);

        final seed = _random.nextInt(10000000);
        final outPath = p.join(imagesDir.path, 'mj_${_uuid.v4()}.jpg');

        try {
          if (settingsService.imageProvider == 'dalle' && settingsService.hasLlmKey) {
            final path = await _generateDalle(client, prompt, outPath);
            if (path != null) {
              savedPaths.add(path);
              continue;
            }
          }

          // Default / Fast Flux generation via Pollinations
          final path = await _generatePollinations(client, prompt, seed, width, height, outPath);
          if (path != null) {
            savedPaths.add(path);
          }
        } catch (_) {}
      }
    } finally {
      client.close();
    }

    return savedPaths;
  }

  (int, int) _dimensionsForAspectRatio(String ar) {
    switch (ar) {
      case '16:9':
        return (1024, 576);
      case '9:16':
        return (576, 1024);
      case '4:3':
        return (1024, 768);
      case '3:2':
        return (960, 640);
      case '1:1':
      default:
        return (768, 768);
    }
  }

  Future<String?> _generatePollinations(
    http.Client client,
    String prompt,
    int seed,
    int width,
    int height,
    String outPath,
  ) async {
    final cleanPrompt = Uri.encodeComponent(prompt);
    final url = Uri.parse(
      'https://image.pollinations.ai/prompt/$cleanPrompt?seed=$seed&width=$width&height=$height&model=flux&nologo=true',
    );

    final response = await client.get(url).timeout(const Duration(seconds: 40));
    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      final file = File(outPath);
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    }
    return null;
  }

  Future<String?> _generateDalle(
    http.Client client,
    String prompt,
    String outPath,
  ) async {
    final response = await client.post(
      Uri.parse('https://api.openai.com/v1/images/generations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${settingsService.imageApiKey}',
      },
      body: jsonEncode({
        'model': 'dall-e-3',
        'prompt': prompt,
        'n': 1,
        'size': '1024x1024',
        'response_format': 'b64_json',
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final b64 = json['data']?[0]?['b64_json'] as String?;
      if (b64 != null) {
        final bytes = base64Decode(b64);
        final file = File(outPath);
        await file.writeAsBytes(bytes);
        return file.path;
      }
    }
    return null;
  }
}
