import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../audio_player/audio_player_controller.dart';
import '../../cloning/voice_clone_service.dart';


class CloneVoiceDialog extends StatefulWidget {
  final VoiceCloneService cloneService;
  final AudioPlayerController audioController;

  const CloneVoiceDialog({
    super.key,
    required this.cloneService,
    required this.audioController,
  });

  @override
  State<CloneVoiceDialog> createState() => _CloneVoiceDialogState();
}

class _CloneVoiceDialogState extends State<CloneVoiceDialog> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  late final TabController _tabController;

  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _timer;
  String? _samplePath;
  bool _isCloning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_isRecording) {
      widget.cloneService.cancelRecording();
    }
    _nameController.dispose();
    _descController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    setState(() => _errorMessage = null);
    if (_isRecording) {
      _timer?.cancel();
      try {
        final path = await widget.cloneService.stopRecording();
        setState(() {
          _isRecording = false;
          _samplePath = path;
        });
      } catch (e) {
        setState(() {
          _isRecording = false;
          _errorMessage = 'Failed to stop recording: $e';
        });
      }
    } else {
      try {
        await widget.cloneService.startRecording();
        setState(() {
          _isRecording = true;
          _recordSeconds = 0;
          _samplePath = null;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (mounted) setState(() => _recordSeconds++);
        });
      } catch (e) {
        setState(() {
          _isRecording = false;
          _errorMessage = 'Failed to start recording: $e';
        });
      }
    }
  }

  Future<void> _pickAudioFile() async {
    setState(() => _errorMessage = null);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
      );
      if (result.isNotEmpty && result.first.path != null) {
        setState(() {
          _samplePath = result.first.path;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to pick audio file: $e');
    }
  }

  Future<void> _clone() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a voice name');
      return;
    }
    if (_samplePath == null) {
      setState(() => _errorMessage = 'Please record or upload an audio sample first');
      return;
    }

    setState(() {
      _isCloning = true;
      _errorMessage = null;
    });

    try {
      final voice = await widget.cloneService.cloneVoice(
        name: name,
        description: _descController.text.trim(),
        audioFilePath: _samplePath!,
      );
      if (mounted) Navigator.of(context).pop(voice);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCloning = false;
          _errorMessage = 'Cloning error: $e';
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.record_voice_over, color: Colors.purpleAccent),
          SizedBox(width: 8),
          Text('Clone Voice'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Voice Name',
                  hintText: 'e.g. My Voice, Jordan, Narrator',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g. Calm, expressive, conversational tone',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.mic), text: 'Record Sample'),
                  Tab(icon: Icon(Icons.file_upload), text: 'Upload Audio'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 170,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Record Mic
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatDuration(_recordSeconds),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: _isRecording ? Colors.redAccent : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRecording
                              ? 'Recording... speak naturally (30s - 2min recommended)'
                              : _samplePath != null
                                  ? 'Recording saved! Ready to clone.'
                                  : 'Press record to speak a sample',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _isCloning ? null : _toggleRecording,
                          style: FilledButton.styleFrom(
                            backgroundColor: _isRecording ? Colors.redAccent : Colors.purpleAccent,
                          ),
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                        ),
                      ],
                    ),
                    // Tab 2: Upload File
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _isCloning ? null : _pickAudioFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Select Audio File (.mp3, .wav, .m4a)'),
                        ),
                        const SizedBox(height: 12),
                        if (_samplePath != null)
                          Text(
                            'Selected: ${_samplePath!.split(RegExp(r'[\\/]')).last}',
                            style: const TextStyle(fontSize: 12, color: Colors.greenAccent),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          const Text(
                            'Upload a 30s – 2min clean audio sample without background noise.',
                            style: TextStyle(fontSize: 12, color: Colors.white60),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_samplePath != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.audiotrack, size: 20, color: Colors.purpleAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sample: ${_samplePath!.split(RegExp(r'[\\/]')).last}',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_arrow, size: 20),
                        tooltip: 'Preview Sample',
                        onPressed: () => widget.audioController.play(_samplePath!),
                      ),
                    ],
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],
              if (_isCloning) ...[
                const SizedBox(height: 14),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Cloning voice profile...', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCloning ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isCloning ? null : _clone,
          child: const Text('Create Voice'),
        ),
      ],
    );
  }
}
