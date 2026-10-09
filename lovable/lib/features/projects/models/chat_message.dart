import 'dart:convert';

class ChatMessage {
  final String id;
  final String projectId;
  final String role; // 'user' or 'assistant'
  final String content;
  final List<String> filesChanged;
  final int createdAt;

  const ChatMessage({
    required this.id,
    required this.projectId,
    required this.role,
    required this.content,
    this.filesChanged = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'role': role,
      'content': content,
      'files_changed_json': jsonEncode(filesChanged),
      'created_at': createdAt,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    List<String> files = [];
    if (map['files_changed_json'] != null) {
      try {
        final decoded = jsonDecode(map['files_changed_json'] as String);
        if (decoded is List) {
          files = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return ChatMessage(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      role: map['role'] as String,
      content: map['content'] as String,
      filesChanged: files,
      createdAt: map['created_at'] as int,
    );
  }
}
