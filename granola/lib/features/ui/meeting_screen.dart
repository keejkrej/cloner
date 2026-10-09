import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../meetings/models/meeting.dart';

import '../meetings/meeting_repository.dart';
import '../notes/notes_enhancement_service.dart';
import '../stt/audio_transcription_service.dart';

class MeetingScreen extends StatefulWidget {
  final Meeting initialMeeting;
  final MeetingRepository repository;
  final AudioTranscriptionService transcriptionService;
  final NotesEnhancementService enhancementService;

  const MeetingScreen({
    super.key,
    required this.initialMeeting,
    required this.repository,
    required this.transcriptionService,
    required this.enhancementService,
  });

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> with SingleTickerProviderStateMixin {
  late Meeting _meeting;
  late final TextEditingController _scratchNotesController;
  final _scrollController = ScrollController();
  late final TabController _tabController;

  bool _isTranscribing = false;
  bool _isEnhancing = false;
  String? _enhancedNotes;

  final Map<String, Color> _speakerColors = {};
  final List<Color> _palette = [
    Colors.tealAccent,
    Colors.purpleAccent,
    Colors.amberAccent,
    Colors.lightBlueAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
  ];

  @override
  void initState() {
    super.initState();
    _meeting = widget.initialMeeting;
    _scratchNotesController = TextEditingController(text: _meeting.scratchNotes);
    _enhancedNotes = _meeting.enhancedNotes;
    _tabController = TabController(length: 2, vsync: this, initialIndex: _enhancedNotes != null ? 1 : 0);
  }

  Color _getColorForSpeaker(String speaker) {
    if (!_speakerColors.containsKey(speaker)) {
      final index = _speakerColors.length % _palette.length;
      _speakerColors[speaker] = _palette[index];
    }
    return _speakerColors[speaker]!;
  }

  Future<void> _toggleTranscription() async {
    if (_isTranscribing) {
      await widget.transcriptionService.stop();
      setState(() => _isTranscribing = false);
    } else {
      setState(() => _isTranscribing = true);
      await widget.transcriptionService.start(
        meetingId: _meeting.id,
        onUtterance: (utterance) async {
          await widget.repository.saveUtterance(utterance);
          if (mounted) {
            setState(() {
              _meeting.utterances.add(utterance);
            });
            _scrollToBottom();
          }
        },
      );
    }
  }

  Future<void> _enhanceNotes() async {
    setState(() => _isEnhancing = true);
    final scratch = _scratchNotesController.text;

    try {
      final enhanced = await widget.enhancementService.enhanceNotes(
        scratchNotes: scratch,
        utterances: _meeting.utterances,
      );

      await widget.repository.updateNotes(
        meetingId: _meeting.id,
        scratchNotes: scratch,
        enhancedNotes: enhanced,
      );

      if (mounted) {
        setState(() {
          _enhancedNotes = enhanced;
          _isEnhancing = false;
        });
        _tabController.animateTo(1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes enhanced successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEnhancing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enhancement failed: $e')),
        );
      }
    }
  }

  Future<void> _saveScratchNotes(String text) async {
    await widget.repository.updateNotes(
      meetingId: _meeting.id,
      scratchNotes: text,
      enhancedNotes: _enhancedNotes,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    widget.transcriptionService.stop();
    _scratchNotesController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _meeting.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${_meeting.utterances.length} utterances captured',
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          // Live transcription toggle
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _isTranscribing ? Colors.redAccent : Colors.teal.shade700,
            ),
            onPressed: _toggleTranscription,
            icon: Icon(_isTranscribing ? Icons.stop : Icons.mic),
            label: Text(_isTranscribing ? 'Stop Meeting' : 'Start Meeting'),
          ),
          const SizedBox(width: 8),
          // Enhance Notes button
          FilledButton.tonalIcon(
            onPressed: _isEnhancing ? null : _enhanceNotes,
            icon: _isEnhancing
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome, color: Colors.tealAccent, size: 18),
            label: const Text('Enhance Notes'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Left 50%: Live Diarized Transcript
          Expanded(
            flex: 50,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141720),
                border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transcript status bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: const Color(0xFF1B1F2C),
                    child: Row(
                      children: [
                        const Icon(Icons.record_voice_over, size: 18, color: Colors.tealAccent),
                        const SizedBox(width: 8),
                        const Text(
                          'Live Transcript & Diarization',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Spacer(),
                        if (_isTranscribing)
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'LISTENING LIVE',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          )
                        else
                          const Text(
                            'PAUSED',
                            style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),

                  // Utterances stream
                  Expanded(
                    child: _meeting.utterances.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mic_none, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No speech captured yet.',
                                  style: TextStyle(color: Colors.white54, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Click "Start Meeting" to stream live audio with speaker attribution.',
                                  style: TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _meeting.utterances.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final u = _meeting.utterances[index];
                              final speakerColor = _getColorForSpeaker(u.speakerLabel);

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: speakerColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: speakerColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            u.speakerLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: speakerColor,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          u.formattedTime,
                                          style: const TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'monospace'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      u.text,
                                      style: const TextStyle(fontSize: 13, height: 1.45, color: Colors.white),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Right 50%: Notes (Scratch Editor & AI Enhanced Notes)
          Expanded(
            flex: 50,
            child: Container(
              color: const Color(0xFF11141B),
              child: Column(
                children: [
                  // Tab header
                  Container(
                    color: const Color(0xFF1B1F2C),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.tealAccent,
                      unselectedLabelColor: Colors.white54,
                      indicatorColor: Colors.tealAccent,
                      tabs: const [
                        Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Scratch Notes'),
                        Tab(icon: Icon(Icons.auto_awesome, size: 18), text: 'AI Enhanced Notes'),
                      ],
                    ),
                  ),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Scratch Notes Editor
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Your Rough Meeting Notes',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_scratchNotesController.text.length} chars',
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: TextField(
                                  controller: _scratchNotesController,
                                  maxLines: null,
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  style: const TextStyle(fontSize: 14, height: 1.5),
                                  decoration: InputDecoration(
                                    hintText: 'Type your rough notes, key thoughts, and personal action items here during the meeting...\n\nGranola\'s AI will merge these with the live transcript into clean executive notes.',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    filled: true,
                                    fillColor: const Color(0xFF171B26),
                                  ),
                                  onChanged: (val) {
                                    setState(() {});
                                    _saveScratchNotes(val);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tab 2: AI Enhanced Notes
                        _enhancedNotes == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.auto_awesome, size: 48, color: Colors.tealAccent),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No enhanced notes generated yet',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    const SizedBox(
                                      width: 360,
                                      child: Text(
                                        'Capture some meeting dialogue and scratch notes, then click "Enhance Notes" above.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    FilledButton.icon(
                                      onPressed: _enhanceNotes,
                                      icon: const Icon(Icons.auto_awesome),
                                      label: const Text('Enhance Notes Now'),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    color: Colors.white.withValues(alpha: 0.03),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'Structured Meeting Minutes',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.copy, size: 18),
                                          tooltip: 'Copy Markdown',
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: _enhancedNotes!));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Enhanced notes copied to clipboard')),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(20),
                                      child: MarkdownBody(
                                        data: _enhancedNotes!,
                                        styleSheet: MarkdownStyleSheet(
                                          h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                          h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                                          p: const TextStyle(fontSize: 13, height: 1.5, color: Colors.white),
                                          blockquote: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.amberAccent),
                                          blockquoteDecoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border(left: BorderSide(color: Colors.amberAccent, width: 4)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
