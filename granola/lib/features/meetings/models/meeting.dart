import 'utterance.dart';

class Meeting {
  final String id;
  final String title;
  final String scratchNotes;
  final String? enhancedNotes;
  final List<Utterance> utterances;
  final int createdAt;
  final int updatedAt;

  const Meeting({
    required this.id,
    required this.title,
    required this.scratchNotes,
    this.enhancedNotes,
    this.utterances = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Meeting copyWith({
    String? id,
    String? title,
    String? scratchNotes,
    String? enhancedNotes,
    List<Utterance>? utterances,
    int? createdAt,
    int? updatedAt,
  }) {
    return Meeting(
      id: id ?? this.id,
      title: title ?? this.title,
      scratchNotes: scratchNotes ?? this.scratchNotes,
      enhancedNotes: enhancedNotes ?? this.enhancedNotes,
      utterances: utterances ?? this.utterances,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'scratch_notes': scratchNotes,
      'enhanced_notes': enhancedNotes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Meeting.fromMap(Map<String, dynamic> map, {List<Utterance> utterances = const []}) {
    return Meeting(
      id: map['id'] as String,
      title: map['title'] as String,
      scratchNotes: map['scratch_notes'] as String,
      enhancedNotes: map['enhanced_notes'] as String?,
      utterances: utterances,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }
}
