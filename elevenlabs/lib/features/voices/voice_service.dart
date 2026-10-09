import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/db/database_service.dart';
import '../../core/settings/settings_service.dart';
import 'models/voice.dart';

class VoiceService {
  final SettingsService _settingsService;

  VoiceService(this._settingsService);

  Future<List<Voice>> getVoices() async {
    final db = await DatabaseService.database;
    final rows = await db.query('voices', orderBy: 'created_at ASC');

    if (rows.isEmpty) {
      // Seed default voices
      final batch = db.batch();
      for (final v in Voice.defaultPremadeVoices) {
        batch.insert('voices', v.toMap());
      }
      await batch.commit(noResult: true);
      return List.from(Voice.defaultPremadeVoices);
    }

    return rows.map((r) => Voice.fromMap(r)).toList();
  }

  Future<void> addVoice(Voice voice) async {
    final db = await DatabaseService.database;
    await db.insert('voices', voice.toMap());
  }

  Future<void> deleteVoice(String voiceId) async {
    final db = await DatabaseService.database;
    await db.delete('voices', where: 'id = ?', whereArgs: [voiceId]);
  }

  /// Optional: sync remote voices from ElevenLabs API if key is present
  Future<List<Voice>> syncRemoteVoices() async {
    final key = _settingsService.elevenLabsApiKey;
    if (key.isEmpty) return await getVoices();

    try {
      final response = await http.get(
        Uri.parse('https://api.elevenlabs.io/v1/voices'),
        headers: {'xi-api-key': key},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List voicesJson = data['voices'] ?? [];
        final db = await DatabaseService.database;

        for (final item in voicesJson) {
          final id = item['voice_id'] as String;
          final name = item['name'] as String;
          final category = (item['category'] == 'cloned') ? 'cloned' : 'premade';
          final desc = item['description'] ?? '${category.toUpperCase()} voice';

          await db.insert(
            'voices',
            {
              'id': id,
              'name': name,
              'category': category,
              'description': desc,
              'sample_path': null,
              'created_at': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: null, // let existing stay or ignore
          );
        }
      }
    } catch (_) {
      // Ignore network errors and return local voices
    }

    return await getVoices();
  }
}
