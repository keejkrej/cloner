class SearchThread {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  SearchThread({
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

  factory SearchThread.fromMap(Map<String, dynamic> map) => SearchThread(
    id: map['id'] as String,
    title: map['title'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
  );
}

class ThreadMessage {
  final String id;
  final String threadId;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime createdAt;

  ThreadMessage({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'thread_id': threadId,
    'role': role,
    'content': content,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory ThreadMessage.fromMap(Map<String, dynamic> map) => ThreadMessage(
    id: map['id'] as String,
    threadId: map['thread_id'] as String,
    role: map['role'] as String,
    content: map['content'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );

  ThreadMessage copyWith({String? content}) {
    return ThreadMessage(
      id: id,
      threadId: threadId,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
    );
  }
}

class SourceCard {
  final String id;
  final String threadId;
  final int indexNum; // 1-based index [1], [2], ...
  final String title;
  final String url;
  final String snippet;
  final double score;

  SourceCard({
    required this.id,
    required this.threadId,
    required this.indexNum,
    required this.title,
    required this.url,
    required this.snippet,
    required this.score,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'thread_id': threadId,
    'index_num': indexNum,
    'title': title,
    'url': url,
    'snippet': snippet,
    'score': score,
  };

  factory SourceCard.fromMap(Map<String, dynamic> map) => SourceCard(
    id: map['id'] as String,
    threadId: map['thread_id'] as String,
    indexNum: map['index_num'] as int,
    title: map['title'] as String,
    url: map['url'] as String,
    snippet: map['snippet'] as String,
    score: (map['score'] as num).toDouble(),
  );
}

class RawSearchResult {
  final String title;
  final String url;
  final String content;

  RawSearchResult({
    required this.title,
    required this.url,
    required this.content,
  });
}

class RerankedChunk {
  final int sourceIndex;
  final String title;
  final String url;
  final String text;
  final double relevanceScore;

  RerankedChunk({
    required this.sourceIndex,
    required this.title,
    required this.url,
    required this.text,
    required this.relevanceScore,
  });
}
