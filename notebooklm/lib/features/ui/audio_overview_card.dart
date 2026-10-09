import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../notebook/models.dart';
import '../notebook/notebook_service.dart';

class AudioOverviewCard extends StatefulWidget {
  final NotebookService notebookService;

  const AudioOverviewCard({super.key, required this.notebookService});

  @override
  State<AudioOverviewCard> createState() => _AudioOverviewCardState();
}

class _AudioOverviewCardState extends State<AudioOverviewCard> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _showTranscript = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(AudioOverview overview) async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      final file = File(overview.audioPath);
      if (await file.exists()) {
        await _player.play(DeviceFileSource(overview.audioPath));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notebookService,
      builder: (context, _) {
        final overview = widget.notebookService.audioOverview;
        final isGenerating = widget.notebookService.isGeneratingAudio;
        final progressText = widget.notebookService.audioProgressText;

        if (isGenerating) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2638),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6C8CFF).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C8CFF)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Generating Audio Overview (2 Hosts)...',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(progressText, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (overview == null) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1B202E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.podcasts, color: Color(0xFF6C8CFF), size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audio Overview',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Listen to a 2-host podcast conversation (Alex & Sam) summarizing your sources.',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C8CFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 14),
                  label: const Text('Generate', style: TextStyle(fontSize: 12)),
                  onPressed: widget.notebookService.sources.isEmpty
                      ? null
                      : () => widget.notebookService.generateAudioOverview(),
                ),
              ],
            ),
          );
        }

        final isPlaying = _playerState == PlayerState.playing;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1B202E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6C8CFF).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C8CFF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: const Color(0xFF6C8CFF)),
                      iconSize: 20,
                      onPressed: () => _togglePlay(overview),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deep Dive: 2-Host Podcast (Alex & Sam)',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${overview.script.length} turns · Source grounded audio',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(_showTranscript ? Icons.expand_less : Icons.expand_more, size: 16, color: Colors.white60),
                    label: Text(_showTranscript ? 'Hide Script' : 'View Script', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    onPressed: () => setState(() => _showTranscript = !_showTranscript),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16, color: Colors.white54),
                    tooltip: 'Regenerate Overview',
                    onPressed: () => widget.notebookService.generateAudioOverview(),
                  ),
                ],
              ),

              if (_duration.inSeconds > 0) ...[
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: const Color(0xFF6C8CFF),
                    inactiveTrackColor: Colors.white12,
                    thumbColor: const Color(0xFF6C8CFF),
                  ),
                  child: Slider(
                    value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                    max: _duration.inSeconds.toDouble(),
                    onChanged: (val) {
                      _player.seek(Duration(seconds: val.toInt()));
                    },
                  ),
                ),
              ],

              if (_showTranscript) ...[
                const Divider(color: Colors.white12, height: 16),
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: overview.script.length,
                    itemBuilder: (context, i) {
                      final line = overview.script[i];
                      final isAlex = line.speaker.toLowerCase() == 'alex';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isAlex ? Colors.indigo.withValues(alpha: 0.3) : Colors.teal.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                line.speaker,
                                style: TextStyle(
                                  color: isAlex ? Colors.indigoAccent : Colors.tealAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                line.text,
                                style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
