class Utterance {
  final String id;
  final String meetingId;
  final String speakerLabel; // e.g. "Speaker 0", "Speaker 1", "You"
  final String text;
  final int timestampMs;
  final int createdAt;

  const Utterance({
    required this.id,
    required this.meetingId,
    required this.speakerLabel,
    required this.text,
    required this.timestampMs,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meeting_id': meetingId,
      'speaker_label': speakerLabel,
      'text': text,
      'timestamp_ms': timestampMs,
      'created_at': createdAt,
    };
  }

  factory Utterance.fromMap(Map<String, dynamic> map) {
    return Utterance(
      id: map['id'] as String,
      meetingId: map['meeting_id'] as String,
      speakerLabel: map['speaker_label'] as String,
      text: map['text'] as String,
      timestampMs: map['timestamp_ms'] as int,
      createdAt: map['created_at'] as int,
    );
  }

  String get formattedTime {
    final seconds = timestampMs ~/ 1000;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
