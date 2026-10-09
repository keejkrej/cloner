import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../core/settings/settings_service.dart';
import '../audio_player/audio_player_controller.dart';
import '../cloning/voice_clone_service.dart';
import '../history/history_service.dart';
import '../history/models/generation.dart';
import '../tts/text_chunker.dart';
import '../tts/tts_service.dart';
import '../voices/models/voice.dart';
import '../voices/voice_service.dart';
import 'dialogs/clone_voice_dialog.dart';
import 'dialogs/settings_dialog.dart';

class HomeScreen extends StatefulWidget {
  final SettingsService settingsService;
  final VoiceService voiceService;
  final TtsService ttsService;
  final VoiceCloneService cloneService;
  final HistoryService historyService;
  final AudioPlayerController audioController;

  const HomeScreen({
    super.key,
    required this.settingsService,
    required this.voiceService,
    required this.ttsService,
    required this.cloneService,
    required this.historyService,
    required this.audioController,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _textController = TextEditingController();
  final _uuid = const Uuid();

  List<Voice> _voices = [];
  Voice? _selectedVoice;
  List<Generation> _history = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  String _generationProgress = '';
  Generation? _activeGeneration;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final voices = await widget.voiceService.getVoices();
    final history = await widget.historyService.getGenerations();

    setState(() {
      _voices = voices;
      if (voices.isNotEmpty) {
        _selectedVoice = voices.first;
      }
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _generateSpeech() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text to synthesize')),
      );
      return;
    }
    if (_selectedVoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a voice')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationProgress = 'Preparing text...';
    });

    try {
      final audioPath = await widget.ttsService.synthesize(
        voiceId: _selectedVoice!.id,
        voiceName: _selectedVoice!.name,
        text: text,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _generationProgress = p.status;
            });
          }
        },
      );

      final gen = Generation(
        id: _uuid.v4(),
        voiceId: _selectedVoice!.id,
        voiceName: _selectedVoice!.name,
        fullText: text,
        audioPath: audioPath,
        characterCount: text.length,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await widget.historyService.saveGeneration(gen);
      final history = await widget.historyService.getGenerations();

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _activeGeneration = gen;
          _history = history;
        });
        // Auto-play generated speech
        widget.audioController.play(audioPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generation failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _openCloneDialog() async {
    final Voice? newVoice = await showDialog<Voice>(
      context: context,
      builder: (ctx) => CloneVoiceDialog(
        cloneService: widget.cloneService,
        audioController: widget.audioController,
      ),
    );

    if (newVoice != null) {
      final voices = await widget.voiceService.getVoices();
      setState(() {
        _voices = voices;
        _selectedVoice = newVoice;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cloned voice "${newVoice.name}" added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _openSettings() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => SettingsDialog(settingsService: widget.settingsService),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  Future<void> _exportAudio(Generation gen) async {
    try {
      final src = File(gen.audioPath);
      if (!await src.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio file not found')),
          );
        }
        return;
      }

      final bytes = await src.readAsBytes();
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Export Audio As',
        fileName: 'speech_${gen.voiceName}_${DateTime.now().millisecondsSinceEpoch}.mp3',
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav'],
        bytes: bytes,
      );

      if (uri != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio exported to: ${uri.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _deleteGeneration(Generation gen) async {
    await widget.historyService.deleteGeneration(gen.id, gen.audioPath);
    if (_activeGeneration?.id == gen.id) {
      widget.audioController.stop();
      _activeGeneration = null;
    }
    final history = await widget.historyService.getGenerations();
    setState(() => _history = history);
  }

  void _loadPreset(String type) {
    if (type == 'short') {
      _textController.text =
          'Welcome to the ElevenLabs voice synthesizer. The future of synthetic speech is remarkably expressive, natural, and human-like.';
    } else if (type == 'long') {
      _textController.text = '''
In the heart of the digital revolution, speech synthesis has transcended mechanical cadence to become a living, breathing art form. Where once automated voices sounded jagged and monotone, modern neural acoustic models understand cadence, emotional depth, punctuation, and the subtle warmth of the human breath.

Consider the craft of long-form audiobooks. When a narrator reads through chapter after chapter of an epic story, their voice navigates quiet tension, thunderous conflict, thoughtful contemplation, and dialogue between a dozen distinct personalities. Replicating this fidelity requires not just phonetic translation, but semantic comprehension.

As the text expands across pages and thousands of words, text segmentation algorithms must slice each paragraph at natural pauses, ensuring that the synthesized audio frames transition seamlessly without pops, clicks, or abrupt jumps in pitch. Every sentence flows effortlessly into the next, maintaining consistent volume, timbre, and pace.

Whether giving voice to historical figures, creating dynamic characters for virtual worlds, or providing accessible audio for the visually impaired, generative voice cloning and streaming synthesis represent a monumental leap forward in pair programming, creative media, and human-computer symbiosis.
'''.trim();
    } else {
      _textController.clear();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = _textController.text;
    final chunks = text.isEmpty ? 0 : TextChunker.chunkText(text).length;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.graphic_eq, color: Colors.purpleAccent),
            SizedBox(width: 10),
            Text(
              'ElevenLabs Voice Studio',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          FilledButton.tonalIcon(
            onPressed: _openCloneDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Clone Voice'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync Voices from ElevenLabs',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final v = await widget.voiceService.syncRemoteVoices();
              if (!mounted) return;
              setState(() => _voices = v);
              messenger.showSnackBar(
                SnackBar(content: Text('Synced ${v.length} voices')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Left 65%: Main generation canvas
                Expanded(
                  flex: 65,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Voice Selector row
                        _buildVoiceSelectorBar(),
                        const SizedBox(height: 16),

                        // Text input toolbar (presets & stats)
                        Row(
                          children: [
                            const Text(
                              'Text to Synthesize',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _loadPreset('short'),
                              icon: const Icon(Icons.short_text, size: 16),
                              label: const Text('Short Sample', style: TextStyle(fontSize: 12)),
                            ),
                            TextButton.icon(
                              onPressed: () => _loadPreset('long'),
                              icon: const Icon(Icons.article, size: 16),
                              label: const Text('Long Form (>1 Page)', style: TextStyle(fontSize: 12)),
                            ),
                            TextButton(
                              onPressed: () => _loadPreset('clear'),
                              child: const Text('Clear', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Text Input
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(fontSize: 15, height: 1.5),
                            decoration: InputDecoration(
                              hintText: 'Type, paste, or load a paragraph or long article to synthesize into natural speech...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Stats & Generate row
                        Row(
                          children: [
                            Text(
                              '${text.length} characters • ${text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words • $chunks chunk${chunks == 1 ? '' : 's'}',
                              style: const TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                            const Spacer(),
                            if (_isGenerating) ...[
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _generationProgress,
                                style: const TextStyle(color: Colors.purpleAccent, fontSize: 13),
                              ),
                              const SizedBox(width: 16),
                            ],
                            FilledButton.icon(
                              onPressed: _isGenerating ? null : _generateSpeech,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                backgroundColor: Colors.purpleAccent.shade700,
                              ),
                              icon: const Icon(Icons.play_circle_fill),
                              label: const Text(
                                'Generate Speech',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Active Audio Player
                        if (_activeGeneration != null)
                          _buildAudioPlayerCard(_activeGeneration!),
                      ],
                    ),
                  ),
                ),

                const VerticalDivider(width: 1),

                // Right 35%: Generations History
                Expanded(
                  flex: 35,
                  child: _buildHistoryPanel(),
                ),
              ],
            ),
    );
  }

  Widget _buildVoiceSelectorBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_none, color: Colors.purpleAccent),
          const SizedBox(width: 10),
          const Text('Voice:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Voice>(
                value: _selectedVoice,
                isExpanded: true,
                items: _voices.map((v) {
                  return DropdownMenuItem<Voice>(
                    value: v,
                    child: Row(
                      children: [
                        Text(
                          v.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: v.isCloned
                                ? Colors.purpleAccent.withValues(alpha: 0.2)
                                : Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            v.isCloned ? 'CLONED' : 'PREMADE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: v.isCloned ? Colors.purpleAccent : Colors.lightBlueAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            v.description,
                            style: const TextStyle(fontSize: 12, color: Colors.white54),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedVoice = v);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.purpleAccent),
            tooltip: 'Clone New Voice',
            onPressed: _openCloneDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayerCard(Generation gen) {
    return ListenableBuilder(
      listenable: widget.audioController,
      builder: (context, _) {
        final isPlaying = widget.audioController.isPlaying &&
            widget.audioController.currentAudioPath == gen.audioPath;
        final position = widget.audioController.position;
        final duration = widget.audioController.duration;
        final maxDuration = duration.inMilliseconds.toDouble();
        final currentPos = position.inMilliseconds.toDouble().clamp(0.0, maxDuration > 0 ? maxDuration : 1.0);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.purpleAccent),
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    iconSize: 28,
                    onPressed: () => widget.audioController.toggle(gen.audioPath),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice: ${gen.voiceName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          '${_formatDuration(position)} / ${_formatDuration(duration)} • ${gen.characterCount} characters',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, size: 20),
                    tooltip: 'Export Audio File',
                    onPressed: () => _exportAudio(gen),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy Text',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: gen.fullText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Text copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: Colors.purpleAccent,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.purpleAccent,
                ),
                child: Slider(
                  value: currentPos,
                  min: 0.0,
                  max: maxDuration > 0 ? maxDuration : 1.0,
                  onChanged: (val) {
                    widget.audioController.seek(Duration(milliseconds: val.toInt()));
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryPanel() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                const Icon(Icons.history, size: 20, color: Colors.white70),
                const SizedBox(width: 8),
                const Text(
                  'Recent Generations',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '${_history.length}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _history.isEmpty
                ? const Center(
                    child: Text(
                      'No audio generated yet.\nEnter text and hit Generate!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: _history.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final gen = _history[index];
                      return ListenableBuilder(
                        listenable: widget.audioController,
                        builder: (context, _) {
                          final isCurrent = widget.audioController.currentAudioPath == gen.audioPath;
                          final isPlaying = isCurrent && widget.audioController.isPlaying;

                          return ListTile(
                            leading: IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                color: isPlaying ? Colors.purpleAccent : Colors.white70,
                                size: 32,
                              ),
                              onPressed: () {
                                setState(() => _activeGeneration = gen);
                                widget.audioController.toggle(gen.audioPath);
                              },
                            ),
                            title: Row(
                              children: [
                                Text(
                                  gen.voiceName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const Spacer(),
                                Text(
                                  '${gen.characterCount} chars',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              gen.fullText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.white60),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'export') _exportAudio(gen);
                                if (val == 'use_text') {
                                  _textController.text = gen.fullText;
                                  setState(() {});
                                }
                                if (val == 'delete') _deleteGeneration(gen);
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'use_text',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_note, size: 18),
                                      SizedBox(width: 8),
                                      Text('Use Text'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'export',
                                  child: Row(
                                    children: [
                                      Icon(Icons.download, size: 18),
                                      SizedBox(width: 8),
                                      Text('Export Audio'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            selected: _activeGeneration?.id == gen.id,
                            onTap: () {
                              setState(() => _activeGeneration = gen);
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
