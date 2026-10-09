import 'dart:convert';

class QaMessage {
  final String id;
  final String matterId;
  final String role; // 'user' or 'assistant'
  final String content;
  final List<String> citations;
  final int createdAt;

  const QaMessage({
    required this.id,
    required this.matterId,
    required this.role,
    required this.content,
    this.citations = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matter_id': matterId,
      'role': role,
      'content': content,
      'citations_json': jsonEncode(citations),
      'created_at': createdAt,
    };
  }

  factory QaMessage.fromMap(Map<String, dynamic> map) {
    List<String> cites = [];
    if (map['citations_json'] != null) {
      try {
        final decoded = jsonDecode(map['citations_json'] as String);
        if (decoded is List) {
          cites = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return QaMessage(
      id: map['id'] as String,
      matterId: map['matter_id'] as String,
      role: map['role'] as String,
      content: map['content'] as String,
      citations: cites,
      createdAt: map['created_at'] as int,
    );
  }
}
