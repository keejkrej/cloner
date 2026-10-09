import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/settings/settings_service.dart';
import '../meetings/meeting_repository.dart';
import '../meetings/models/meeting.dart';
import '../notes/notes_enhancement_service.dart';
import '../stt/audio_transcription_service.dart';
import 'dialogs/settings_dialog.dart';
import 'meeting_screen.dart';

class MeetingListScreen extends StatefulWidget {
  final SettingsService settingsService;
  final MeetingRepository repository;
  final AudioTranscriptionService transcriptionService;
  final NotesEnhancementService enhancementService;

  const MeetingListScreen({
    super.key,
    required this.settingsService,
    required this.repository,
    required this.transcriptionService,
    required this.enhancementService,
  });

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  List<Meeting> _meetings = [];
  bool _isLoading = true;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() => _isLoading = true);
    final meetings = await widget.repository.getAllMeetings();
    setState(() {
      _meetings = meetings;
      _isLoading = false;
    });
  }

  Future<void> _createNewMeeting() async {
    final titleController = TextEditingController(
      text: 'Sprint Standup & Planning — ${DateTime.now().month}/${DateTime.now().day}',
    );

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text('Start New Meeting'),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Meeting Title', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Q4 Executive Product Alignment',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Create & Enter'),
          ),
        ],
      ),
    );

    if (created == true) {
      final title = titleController.text.trim().isEmpty ? 'Untitled Meeting' : titleController.text.trim();
      final meeting = Meeting(
        id: _uuid.v4(),
        title: title,
        scratchNotes: '',
        utterances: [],
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await widget.repository.saveMeeting(meeting);
      await _loadMeetings();

      if (mounted) {
        _openMeeting(meeting);
      }
    }
  }

  Future<void> _openMeeting(Meeting meeting) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeetingScreen(
          initialMeeting: meeting,
          repository: widget.repository,
          transcriptionService: widget.transcriptionService,
          enhancementService: widget.enhancementService,
        ),
      ),
    );
    _loadMeetings();
  }

  Future<void> _deleteMeeting(Meeting meeting) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Meeting?'),
        content: Text('Are you sure you want to delete "${meeting.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.repository.deleteMeeting(meeting.id);
      _loadMeetings();
    }
  }

  Future<void> _openSettings() async {
    await showDialog(
      context: context,
      builder: (ctx) => SettingsDialog(settingsService: widget.settingsService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.notes, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text(
              'Granola AI Meeting Studio',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade700),
            onPressed: _createNewMeeting,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Meeting'),
          ),
          const SizedBox(width: 8),
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
          : _meetings.isEmpty
              ? _buildEmptyState()
              : _buildMeetingsGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.record_voice_over, size: 64, color: Colors.tealAccent),
          ),
          const SizedBox(height: 20),
          const Text(
            'No meetings recorded yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 450,
            child: Text(
              'Granola transcribes conversations live with speaker labels and merges your rough scratch notes into executive-ready minutes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Start Your First Meeting',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onPressed: _createNewMeeting,
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.45,
      ),
      itemCount: _meetings.length,
      itemBuilder: (context, index) {
        final meeting = _meetings[index];
        final hasEnhanced = meeting.enhancedNotes != null && meeting.enhancedNotes!.isNotEmpty;

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          color: Theme.of(context).colorScheme.surface,
          child: InkWell(
            onTap: () => _openMeeting(meeting),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.mic, size: 20, color: Colors.tealAccent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          meeting.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        tooltip: 'Delete',
                        onPressed: () => _deleteMeeting(meeting),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    meeting.scratchNotes.trim().isNotEmpty
                        ? meeting.scratchNotes.trim()
                        : meeting.utterances.isNotEmpty
                            ? meeting.utterances.last.text
                            : 'No notes or transcript yet.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '${meeting.utterances.length} utterances',
                        style: const TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                      const Spacer(),
                      if (hasEnhanced)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ENHANCED',
                            style: TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 16, color: Colors.tealAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
