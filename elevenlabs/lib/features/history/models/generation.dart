class Generation {
  final String id;
  final String voiceId;
  final String voiceName;
  final String fullText;
  final String audioPath;
  final int characterCount;
  final int createdAt;

  const Generation({
    required this.id,
    required this.voiceId,
    required this.voiceName,
    required this.fullText,
    required this.audioPath,
    required this.characterCount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'voice_id': voiceId,
      'voice_name': voiceName,
      'full_text': fullText,
      'audio_path': audioPath,
      'character_count': characterCount,
      'created_at': createdAt,
    };
  }

  factory Generation.fromMap(Map<String, dynamic> map) {
    return Generation(
      id: map['id'] as String,
      voiceId: map['voice_id'] as String,
      voiceName: map['voice_name'] as String,
      fullText: map['full_text'] as String,
      audioPath: map['audio_path'] as String,
      characterCount: map['character_count'] as int,
      createdAt: map['created_at'] as int,
    );
  }
}
