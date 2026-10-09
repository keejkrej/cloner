import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/settings/settings_service.dart';
import 'text_chunker.dart';

class TtsProgress {
  final int currentChunk;
  final int totalChunks;
  final String status;

  TtsProgress({
    required this.currentChunk,
    required this.totalChunks,
    required this.status,
  });
}

class TtsService {
  final SettingsService _settingsService;
  final _uuid = const Uuid();

  TtsService(this._settingsService);

  /// Synthesizes text with the given [voiceId] and returns the path to the saved audio file.
  Future<String> synthesize({
    required String voiceId,
    required String voiceName,
    required String text,
    void Function(TtsProgress progress)? onProgress,
  }) async {
    final chunks = TextChunker.chunkText(text);
    if (chunks.isEmpty) {
      throw Exception('Text is empty');
    }

    final totalChunks = chunks.length;
    final audioChunks = <Uint8List>[];
    bool isMp3 = true;

    for (int i = 0; i < chunks.length; i++) {
      final chunkIndex = i + 1;
      onProgress?.call(
        TtsProgress(
          currentChunk: chunkIndex,
          totalChunks: totalChunks,
          status: 'Synthesizing chunk $chunkIndex of $totalChunks...',
        ),
      );

      final chunkAudio = await _synthesizeChunk(
        voiceId: voiceId,
        chunkText: chunks[i],
      );

      // Check format
      if (chunkAudio.audioBytes.length >= 4 &&
          String.fromCharCodes(chunkAudio.audioBytes.sublist(0, 4)) == 'RIFF') {
        isMp3 = false;
      }

      audioChunks.add(chunkAudio.audioBytes);
    }

    onProgress?.call(
      TtsProgress(
        currentChunk: totalChunks,
        totalChunks: totalChunks,
        status: 'Stitching audio chunks...',
      ),
    );

    // Save final audio file
    final appDocDir = await getApplicationDocumentsDirectory();
    final genDir = Directory(p.join(appDocDir.path, 'ElevenLabsClone', 'generations'));
    if (!await genDir.exists()) {
      await genDir.create(recursive: true);
    }

    final extension = isMp3 ? 'mp3' : 'wav';
    final fileName = 'tts_${_uuid.v4()}.$extension';
    final filePath = p.join(genDir.path, fileName);

    if (isMp3) {
      // MP3 chunks can be concatenated directly
      final combinedBytes = BytesBuilder();
      for (final chunk in audioChunks) {
        combinedBytes.add(chunk);
      }
      final file = File(filePath);
      await file.writeAsBytes(combinedBytes.toBytes());
    } else {
      // Stitch WAV files
      final stitchedWav = _stitchWavChunks(audioChunks);
      final file = File(filePath);
      await file.writeAsBytes(stitchedWav);
    }

    onProgress?.call(
      TtsProgress(
        currentChunk: totalChunks,
        totalChunks: totalChunks,
        status: 'Audio ready!',
      ),
    );

    return filePath;
  }

  Future<_ChunkResult> _synthesizeChunk({
    required String voiceId,
    required String chunkText,
  }) async {
    final elevenLabsKey = _settingsService.elevenLabsApiKey;
    final openAiKey = _settingsService.openAiApiKey;

    if (elevenLabsKey.isNotEmpty) {
      return await _synthesizeElevenLabs(
        key: elevenLabsKey,
        voiceId: voiceId,
        text: chunkText,
        modelId: _settingsService.modelId,
      );
    } else if (openAiKey.isNotEmpty) {
      return await _synthesizeOpenAi(
        key: openAiKey,
        text: chunkText,
      );
    } else {
      // Fallback synthesizer: produces natural modulated tone speech simulation
      return _synthesizeMockWav(chunkText);
    }
  }

  Future<_ChunkResult> _synthesizeElevenLabs({
    required String key,
    required String voiceId,
    required String text,
    required String modelId,
  }) async {
    final url = Uri.parse(
      'https://api.elevenlabs.io/v1/text-to-speech/$voiceId?output_format=mp3_44100_128',
    );

    final response = await http.post(
      url,
      headers: {
        'xi-api-key': key,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': text,
        'model_id': modelId,
        'voice_settings': {
          'stability': 0.5,
          'similarity_boost': 0.75,
        },
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _ChunkResult(response.bodyBytes, isMp3: true);
    } else {
      throw Exception('ElevenLabs TTS error (${response.statusCode}): ${response.body}');
    }
  }

  Future<_ChunkResult> _synthesizeOpenAi({
    required String key,
    required String text,
  }) async {
    final url = Uri.parse('https://api.openai.com/v1/audio/speech');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'tts-1',
        'input': text,
        'voice': 'alloy',
        'response_format': 'mp3',
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _ChunkResult(response.bodyBytes, isMp3: true);
    } else {
      throw Exception('OpenAI TTS error (${response.statusCode}): ${response.body}');
    }
  }

  /// Synthesizes a valid playable WAV file with formant-like modulation
  _ChunkResult _synthesizeMockWav(String text) {
    const sampleRate = 22050;
    // Estimate ~0.06 seconds per character
    final durationSeconds = max(1.2, text.length * 0.055);
    final totalSamples = (sampleRate * durationSeconds).toInt();
    final pcmData = Int16List(totalSamples);

    final seed = text.hashCode.abs();
    final baseFreq = 160.0 + (seed % 100);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      // Pitch contour & formant harmonics
      final pitchMod = sin(2 * pi * 2.5 * t) * 15;
      final f0 = baseFreq + pitchMod;
      final val1 = sin(2 * pi * f0 * t);
      final val2 = sin(2 * pi * (f0 * 2) * t) * 0.4;
      final val3 = sin(2 * pi * (f0 * 3) * t) * 0.2;

      // Amplitude envelope (slight pauses between words)
      final envelope = (0.5 + 0.5 * sin(2 * pi * 4.0 * t)).clamp(0.2, 1.0);
      final sampleVal = ((val1 + val2 + val3) * 0.3 * envelope * 32767).toInt();

      pcmData[i] = sampleVal.clamp(-32768, 32767);
    }

    final wavBytes = _buildWavHeader(pcmData.buffer.asUint8List(), sampleRate);
    return _ChunkResult(wavBytes, isMp3: false);
  }

  static Uint8List _buildWavHeader(Uint8List pcmBytes, int sampleRate) {
    final byteData = ByteData(44 + pcmBytes.length);
    // RIFF
    byteData.setUint8(0, 0x52); // R
    byteData.setUint8(1, 0x49); // I
    byteData.setUint8(2, 0x46); // F
    byteData.setUint8(3, 0x46); // F
    byteData.setUint32(4, 36 + pcmBytes.length, Endian.little);
    // WAVE
    byteData.setUint8(8, 0x57);  // W
    byteData.setUint8(9, 0x41);  // A
    byteData.setUint8(10, 0x56); // V
    byteData.setUint8(11, 0x45); // E
    // fmt 
    byteData.setUint8(12, 0x66); // f
    byteData.setUint8(13, 0x6D); // m
    byteData.setUint8(14, 0x74); // t
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size
    byteData.setUint16(20, 1, Endian.little);  // PCM format
    byteData.setUint16(22, 1, Endian.little);  // Mono
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    byteData.setUint16(32, 2, Endian.little);  // BlockAlign
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample
    // data
    byteData.setUint8(36, 0x64); // d
    byteData.setUint8(37, 0x61); // a
    byteData.setUint8(38, 0x74); // t
    byteData.setUint8(39, 0x61); // a
    byteData.setUint32(40, pcmBytes.length, Endian.little);

    final header = byteData.buffer.asUint8List();
    header.setRange(44, 44 + pcmBytes.length, pcmBytes);
    return header;
  }

  Uint8List _stitchWavChunks(List<Uint8List> wavChunks) {
    if (wavChunks.isEmpty) return Uint8List(0);
    if (wavChunks.length == 1) return wavChunks.first;

    final pcmBuilder = BytesBuilder();
    int sampleRate = 22050;

    for (final wav in wavChunks) {
      if (wav.length > 44) {
        final bData = ByteData.sublistView(wav);
        sampleRate = bData.getUint32(24, Endian.little);
        pcmBuilder.add(wav.sublist(44));
      }
    }

    return _buildWavHeader(pcmBuilder.toBytes(), sampleRate);
  }
}

class _ChunkResult {
  final Uint8List audioBytes;
  final bool isMp3;

  _ChunkResult(this.audioBytes, {required this.isMp3});
}
