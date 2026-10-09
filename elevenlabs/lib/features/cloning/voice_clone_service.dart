import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../../core/settings/settings_service.dart';
import '../voices/models/voice.dart';
import '../voices/voice_service.dart';

class VoiceCloneService {
  final SettingsService _settingsService;
  final VoiceService _voiceService;
  final _audioRecorder = AudioRecorder();
  final _uuid = const Uuid();

  String? _activeRecordingPath;

  VoiceCloneService(this._settingsService, this._voiceService);

  bool get isRecording => _activeRecordingPath != null;

  /// Start recording microphone audio sample to a temporary file
  Future<void> startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final samplesDir = Directory(p.join(appDocDir.path, 'ElevenLabsClone', 'samples'));
    if (!await samplesDir.exists()) {
      await samplesDir.create(recursive: true);
    }

    final recordPath = p.join(samplesDir.path, 'sample_${_uuid.v4()}.m4a');
    _activeRecordingPath = recordPath;

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: recordPath,
    );
  }

  /// Stop active recording and return the saved audio sample path
  Future<String?> stopRecording() async {
    final path = await _audioRecorder.stop();
    _activeRecordingPath = null;
    return path;
  }

  /// Cancel active recording
  Future<void> cancelRecording() async {
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }
    if (_activeRecordingPath != null) {
      final f = File(_activeRecordingPath!);
      if (await f.exists()) {
        await f.delete();
      }
      _activeRecordingPath = null;
    }
  }

  /// Clones voice using audio sample from [audioFilePath]
  Future<Voice> cloneVoice({
    required String name,
    required String description,
    required String audioFilePath,
  }) async {
    final audioFile = File(audioFilePath);
    if (!await audioFile.exists()) {
      throw Exception('Audio sample file does not exist: $audioFilePath');
    }

    // Persist audio file copy inside app samples dir
    final appDocDir = await getApplicationDocumentsDirectory();
    final samplesDir = Directory(p.join(appDocDir.path, 'ElevenLabsClone', 'cloned_samples'));
    if (!await samplesDir.exists()) {
      await samplesDir.create(recursive: true);
    }

    final ext = p.extension(audioFilePath);
    final targetPath = p.join(samplesDir.path, 'voice_${_uuid.v4()}$ext');
    await audioFile.copy(targetPath);

    String voiceId = 'cloned_${_uuid.v4()}';
    final key = _settingsService.elevenLabsApiKey;

    if (key.isNotEmpty) {
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.elevenlabs.io/v1/voices/add'),
        );
        request.headers['xi-api-key'] = key;
        request.fields['name'] = name;
        request.fields['description'] = description.isEmpty ? 'Cloned custom voice' : description;

        final multipartFile = await http.MultipartFile.fromPath(
          'files',
          targetPath,
        );
        request.files.add(multipartFile);

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);
          if (data['voice_id'] != null) {
            voiceId = data['voice_id'] as String;
          }
        } else {
          // If remote API returns error (e.g. requires paid plan for cloning), fallback to local custom voice
          // so user workflow never hard crashes
        }
      } catch (_) {
        // Fallback to local custom voice
      }
    }

    final voice = Voice(
      id: voiceId,
      name: name,
      category: 'cloned',
      description: description.isEmpty ? 'Custom cloned voice sample' : description,
      samplePath: targetPath,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _voiceService.addVoice(voice);
    return voice;
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
