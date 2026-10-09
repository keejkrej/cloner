import 'package:flutter_test/flutter_test.dart';
import 'package:granola/core/settings/settings_service.dart';
import 'package:granola/features/meetings/models/meeting.dart';
import 'package:granola/features/meetings/models/utterance.dart';
import 'package:granola/features/notes/notes_enhancement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Models Serialization Tests', () {
    test('Utterance toMap and fromMap', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      const utterance = Utterance(
        id: 'u1',
        meetingId: 'm1',
        speakerLabel: 'Speaker 0',
        text: 'Hello team, let us review the sprint.',
        timestampMs: 4200,
        createdAt: 1234567,
      );

      final map = utterance.toMap();
      final restored = Utterance.fromMap(map);

      expect(restored.id, equals('u1'));
      expect(restored.speakerLabel, equals('Speaker 0'));
      expect(restored.text, equals('Hello team, let us review the sprint.'));
      expect(restored.formattedTime, equals('00:04'));
    });

    test('Meeting toMap and fromMap', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final meeting = Meeting(
        id: 'm1',
        title: 'Product Sync',
        scratchNotes: 'Need to review latency and dark mode',
        enhancedNotes: '# Executive Summary\nAll good.',
        utterances: const [
          Utterance(
            id: 'u1',
            meetingId: 'm1',
            speakerLabel: 'Sarah',
            text: 'Roadmap is clear.',
            timestampMs: 1000,
            createdAt: 1000,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final map = meeting.toMap();
      final restored = Meeting.fromMap(map, utterances: meeting.utterances);

      expect(restored.id, equals('m1'));
      expect(restored.title, equals('Product Sync'));
      expect(restored.scratchNotes, equals('Need to review latency and dark mode'));
      expect(restored.utterances.length, equals(1));
    });
  });

  group('NotesEnhancementService Tests', () {
    test('Enhances scratch notes and transcript into structured sections', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final service = NotesEnhancementService(settings);

      const scratch = 'Check latency SLA and cutover schedule\nDraft release notes';
      final utterances = [
        const Utterance(
          id: 'u1',
          meetingId: 'm1',
          speakerLabel: 'David (Engineering)',
          text: 'Database migration is 90% complete. Zero downtime cutover this Thursday.',
          timestampMs: 4000,
          createdAt: 4000,
        ),
        const Utterance(
          id: 'u2',
          meetingId: 'm1',
          speakerLabel: 'Sarah (Product)',
          text: 'Let us commit to the code freeze on Friday at 5 PM.',
          timestampMs: 8000,
          createdAt: 8000,
        ),
      ];

      final enhanced = await service.enhanceNotes(
        scratchNotes: scratch,
        utterances: utterances,
      );

      expect(enhanced, contains('Executive Summary'));
      expect(enhanced, contains('Key Decisions'));
      expect(enhanced, contains('Action Items'));
      expect(enhanced, contains('My Scratch Notes'));
      expect(enhanced, contains('Check latency SLA'));
    });
  });
}
