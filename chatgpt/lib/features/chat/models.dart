class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory Conversation.fromMap(Map<String, dynamic> map) => Conversation(
    id: map['id'] as String,
    title: map['title'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
  );
}

class Message {
  final String id;
  final String conversationId;
  final String role; // 'user' or 'assistant' or 'system'
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'conversation_id': conversationId,
    'role': role,
    'content': content,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
    id: map['id'] as String,
    conversationId: map['conversation_id'] as String,
    role: map['role'] as String,
    content: map['content'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );

  Message copyWith({String? content}) {
    return Message(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
    );
  }
}

class MemoryItem {
  final String id;
  final String fact;
  final String? sourceConversationId;
  final DateTime createdAt;

  MemoryItem({
    required this.id,
    required this.fact,
    this.sourceConversationId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'fact': fact,
    'source_conversation_id': sourceConversationId,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory MemoryItem.fromMap(Map<String, dynamic> map) => MemoryItem(
    id: map['id'] as String,
    fact: map['fact'] as String,
    sourceConversationId: map['source_conversation_id'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}
