class Character {
  final String id;
  final String name;
  final String avatar; // emoji or single glyph
  final String personality;
  final String speakingStyle;
  final String greeting;
  final String voice; // e.g. 'alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'
  final DateTime createdAt;

  Character({
    required this.id,
    required this.name,
    required this.avatar,
    required this.personality,
    required this.speakingStyle,
    required this.greeting,
    required this.voice,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'personality': personality,
    'speaking_style': speakingStyle,
    'greeting': greeting,
    'voice': voice,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Character.fromMap(Map<String, dynamic> map) => Character(
    id: map['id'] as String,
    name: map['name'] as String,
    avatar: map['avatar'] as String,
    personality: map['personality'] as String,
    speakingStyle: map['speaking_style'] as String,
    greeting: map['greeting'] as String,
    voice: map['voice'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}

class ChatMessage {
  final String id;
  final String characterId;
  final String role; // 'user' or 'assistant'
  final String content;
  final String? audioPath;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.characterId,
    required this.role,
    required this.content,
    this.audioPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'character_id': characterId,
    'role': role,
    'content': content,
    'audio_path': audioPath,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: map['id'] as String,
    characterId: map['character_id'] as String,
    role: map['role'] as String,
    content: map['content'] as String,
    audioPath: map['audio_path'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );

  ChatMessage copyWith({String? content, String? audioPath}) {
    return ChatMessage(
      id: id,
      characterId: characterId,
      role: role,
      content: content ?? this.content,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt,
    );
  }
}

class CharacterMemory {
  final String id;
  final String characterId;
  final String fact;
  final DateTime createdAt;

  CharacterMemory({
    required this.id,
    required this.characterId,
    required this.fact,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'character_id': characterId,
    'fact': fact,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory CharacterMemory.fromMap(Map<String, dynamic> map) => CharacterMemory(
    id: map['id'] as String,
    characterId: map['character_id'] as String,
    fact: map['fact'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}
