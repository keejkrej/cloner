import '../../core/db/database_service.dart';
import 'models/meeting.dart';
import 'models/utterance.dart';

class MeetingRepository {
  Future<List<Meeting>> getAllMeetings() async {
    final db = await DatabaseService.database;
    final meetingRows = await db.query('meetings', orderBy: 'updated_at DESC');

    final meetings = <Meeting>[];
    for (final row in meetingRows) {
      final meetingId = row['id'] as String;
      final utteranceRows = await db.query(
        'transcript_utterances',
        where: 'meeting_id = ?',
        whereArgs: [meetingId],
        orderBy: 'timestamp_ms ASC',
      );
      final utterances = utteranceRows.map((u) => Utterance.fromMap(u)).toList();
      meetings.add(Meeting.fromMap(row, utterances: utterances));
    }
    return meetings;
  }

  Future<Meeting?> getMeeting(String id) async {
    final db = await DatabaseService.database;
    final rows = await db.query('meetings', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    final utteranceRows = await db.query(
      'transcript_utterances',
      where: 'meeting_id = ?',
      whereArgs: [id],
      orderBy: 'timestamp_ms ASC',
    );
    final utterances = utteranceRows.map((u) => Utterance.fromMap(u)).toList();
    return Meeting.fromMap(rows.first, utterances: utterances);
  }

  Future<void> saveMeeting(Meeting meeting) async {
    final db = await DatabaseService.database;
    await db.transaction((txn) async {
      await txn.insert(
        'meetings',
        meeting.toMap(),
        conflictAlgorithm: null,
      );
      await txn.delete('transcript_utterances', where: 'meeting_id = ?', whereArgs: [meeting.id]);
      for (final u in meeting.utterances) {
        await txn.insert('transcript_utterances', u.toMap());
      }
    });
  }

  Future<void> saveUtterance(Utterance utterance) async {
    final db = await DatabaseService.database;
    await db.insert('transcript_utterances', utterance.toMap());
  }

  Future<void> updateNotes({
    required String meetingId,
    required String scratchNotes,
    String? enhancedNotes,
  }) async {
    final db = await DatabaseService.database;
    final values = <String, dynamic>{
      'scratch_notes': scratchNotes,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    if (enhancedNotes != null) {
      values['enhanced_notes'] = enhancedNotes;
    }
    await db.update(
      'meetings',
      values,
      where: 'id = ?',
      whereArgs: [meetingId],
    );
  }

  Future<void> deleteMeeting(String id) async {
    final db = await DatabaseService.database;
    await db.delete('transcript_utterances', where: 'meeting_id = ?', whereArgs: [id]);
    await db.delete('meetings', where: 'id = ?', whereArgs: [id]);
  }
}
