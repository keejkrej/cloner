import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../settings/settings_service.dart';

class VoiceService {
  final SettingsService settingsService;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  final _uuid = const Uuid();

  String? _recordingPath;
  bool _isRecording = false;

  VoiceService({required this.settingsService});

  bool get isRecording => _isRecording;

  void dispose() {
    _audioPlayer.dispose();
    _recorder.dispose();
  }

  /// Synthesizes text to speech using OpenAI-compatible TTS and writes to disk
  Future<String?> synthesizeSpeech({
    required String text,
    required String voice,
    required String characterId,
  }) async {
    if (!settingsService.hasValidApiKey) return null;

    final appDocs = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(appDocs.path, 'CharacterAIClone', 'audio'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final outPath = p.join(audioDir.path, '${characterId}_${_uuid.v4()}.mp3');

    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('https://api.openai.com/v1/audio/speech'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settingsService.ttsApiKey}',
        },
        body: jsonEncode({
          'model': 'tts-1',
          'input': text,
          'voice': voice,
          'response_format': 'mp3',
        }),
      );

      if (response.statusCode == 200) {
        final file = File(outPath);
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (_) {} finally {
      client.close();
    }
    return null;
  }

  /// Plays an audio file aloud
  Future<void> playAudio(String audioPath) async {
    final file = File(audioPath);
    if (await file.exists()) {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(audioPath));
    }
  }

  /// Starts recording audio from the microphone
  Future<bool> startRecording() async {
    if (await _recorder.hasPermission()) {
      final tempDir = await getTemporaryDirectory();
      _recordingPath = p.join(tempDir.path, 'ptt_${_uuid.v4()}.m4a');

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _recordingPath!,
      );
      _isRecording = true;
      return true;
    }
    return false;
  }

  /// Stops recording and transcribes using Whisper STT
  Future<String?> stopRecordingAndTranscribe() async {
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;

    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;

    if (!settingsService.hasValidApiKey) {
      return null;
    }

    // Call Whisper API
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
      );
      request.headers['Authorization'] = 'Bearer ${settingsService.sttApiKey}';
      request.fields['model'] = 'whisper-1';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      if (streamedResponse.statusCode == 200) {
        final respStr = await streamedResponse.stream.bytesToString();
        final json = jsonDecode(respStr);
        return (json['text'] as String?)?.trim();
      }
    } catch (_) {}

    return null;
  }
}
