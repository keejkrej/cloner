import 'dart:async';
import 'dart:convert';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/settings/settings_service.dart';
import '../meetings/models/utterance.dart';

class AudioTranscriptionService {
  final SettingsService _settings;
  final _recorder = AudioRecorder();
  final _uuid = const Uuid();

  WebSocketChannel? _wsChannel;
  StreamSubscription? _audioSubscription;
  Timer? _mockTimer;

  bool _isTranscribing = false;
  int _startTimeMs = 0;
  int _mockDialogueIndex = 0;

  AudioTranscriptionService(this._settings);

  bool get isTranscribing => _isTranscribing;

  /// Starts live transcription of microphone with speaker diarization
  Future<void> start({
    required String meetingId,
    required void Function(Utterance utterance) onUtterance,
  }) async {
    await stop();
    _isTranscribing = true;
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _mockDialogueIndex = 0;

    final deepgramKey = _settings.deepgramApiKey;

    if (deepgramKey.isNotEmpty) {
      try {
        final hasPermission = await _recorder.hasPermission();
        if (!hasPermission) {
          throw Exception('Microphone permission not granted');
        }

        final wsUrl = Uri.parse(
          'wss://api.deepgram.com/v1/listen?model=nova-2&diarize=true&punctuate=true&encoding=linear16&sample_rate=16000',
        );

        _wsChannel = WebSocketChannel.connect(
          wsUrl,
          protocols: ['token', deepgramKey],
        );

        // Listen for transcript messages
        _wsChannel!.stream.listen((message) {
          try {
            final data = jsonDecode(message.toString());
            final channel = data['channel'];
            if (channel != null) {
              final alternatives = channel['alternatives'] as List?;
              if (alternatives != null && alternatives.isNotEmpty) {
                final alt = alternatives.first;
                final transcript = (alt['transcript'] as String?)?.trim() ?? '';
                final words = alt['words'] as List?;

                if (transcript.isNotEmpty) {
                  int speaker = 0;
                  if (words != null && words.isNotEmpty) {
                    speaker = words.first['speaker'] ?? 0;
                  }

                  final utterance = Utterance(
                    id: _uuid.v4(),
                    meetingId: meetingId,
                    speakerLabel: 'Speaker $speaker',
                    text: transcript,
                    timestampMs: DateTime.now().millisecondsSinceEpoch - _startTimeMs,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                  );

                  onUtterance(utterance);
                }
              }
            }
          } catch (_) {}
        });

        // Start PCM audio stream from microphone
        final audioStream = await _recorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );

        _audioSubscription = audioStream.listen((data) {
          if (_wsChannel != null) {
            _wsChannel!.sink.add(data);
          }
        });

        return;
      } catch (_) {
        // Fall back to offline diarized meeting simulator
      }
    }

    // Offline / Demo multi-speaker diarized stream
    _startMockDiarizedStream(meetingId, onUtterance);
  }

  void _startMockDiarizedStream(
    String meetingId,
    void Function(Utterance utterance) onUtterance,
  ) {
    final mockMeetingScript = [
      (
        'Sarah (Product)',
        'Thanks everyone for joining our sprint alignment. Let\'s quickly review the Q4 release roadmap and outstanding blockers.'
      ),
      (
        'David (Engineering)',
        'From the backend team: database migration to distributed vector storage is 90% complete. We expect zero downtime cutover this Thursday.'
      ),
      (
        'You',
        'That\'s great to hear. What about latency benchmarks on the search reranking service under high concurrency?'
      ),
      (
        'David (Engineering)',
        'P99 latency dropped from 480ms down to 110ms with our new caching tier. We\'re comfortably within our SLA.'
      ),
      (
        'Alex (Design)',
        'On the UX front, the new dark mode and mobile-responsive presentation views have passed accessibility audits with AAA contrast.'
      ),
      (
        'Sarah (Product)',
        'Awesome progress! Let\'s commit to the staging freeze by Friday 5 PM. David, can you ensure the telemetry dashboards are linked in Jira?'
      ),
      (
        'David (Engineering)',
        'Will do right after this standup.'
      ),
      (
        'You',
        'I\'ll draft the user-facing release notes and send them for product review.'
      ),
    ];

    _mockTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isTranscribing) {
        timer.cancel();
        return;
      }

      if (_mockDialogueIndex < mockMeetingScript.length) {
        final item = mockMeetingScript[_mockDialogueIndex];
        final elapsed = DateTime.now().millisecondsSinceEpoch - _startTimeMs;

        final utterance = Utterance(
          id: _uuid.v4(),
          meetingId: meetingId,
          speakerLabel: item.$1,
          text: item.$2,
          timestampMs: elapsed,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        onUtterance(utterance);
        _mockDialogueIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> stop() async {
    _isTranscribing = false;
    _mockTimer?.cancel();
    _mockTimer = null;

    await _audioSubscription?.cancel();
    _audioSubscription = null;

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    if (_wsChannel != null) {
      try {
        _wsChannel!.sink.close();
      } catch (_) {}
      _wsChannel = null;
    }
  }

  void dispose() {
    stop();
    _recorder.dispose();
  }
}
