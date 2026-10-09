import 'dart:convert';

class Notebook {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  Notebook({
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

  factory Notebook.fromMap(Map<String, dynamic> map) => Notebook(
    id: map['id'] as String,
    title: map['title'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
  );
}

class NotebookSource {
  final String id;
  final String notebookId;
  final String title;
  final String filePath;
  final int pageCount;
  final DateTime createdAt;

  NotebookSource({
    required this.id,
    required this.notebookId,
    required this.title,
    required this.filePath,
    required this.pageCount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'notebook_id': notebookId,
    'title': title,
    'file_path': filePath,
    'page_count': pageCount,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory NotebookSource.fromMap(Map<String, dynamic> map) => NotebookSource(
    id: map['id'] as String,
    notebookId: map['notebook_id'] as String,
    title: map['title'] as String,
    filePath: map['file_path'] as String,
    pageCount: map['page_count'] as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}

class DocumentChunk {
  final String id;
  final String notebookId;
  final String sourceId;
  final String sourceTitle;
  final int pageNumber;
  final int chunkIndex;
  final String content;

  DocumentChunk({
    required this.id,
    required this.notebookId,
    required this.sourceId,
    required this.sourceTitle,
    required this.pageNumber,
    required this.chunkIndex,
    required this.content,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'notebook_id': notebookId,
    'source_id': sourceId,
    'source_title': sourceTitle,
    'page_number': pageNumber,
    'chunk_index': chunkIndex,
    'content': content,
  };

  factory DocumentChunk.fromMap(Map<String, dynamic> map) => DocumentChunk(
    id: map['id'] as String,
    notebookId: map['notebook_id'] as String,
    sourceId: map['source_id'] as String,
    sourceTitle: map['source_title'] as String,
    pageNumber: map['page_number'] as int,
    chunkIndex: map['chunk_index'] as int,
    content: map['content'] as String,
  );
}

class Citation {
  final String sourceTitle;
  final int pageNumber;
  final String snippet;

  Citation({
    required this.sourceTitle,
    required this.pageNumber,
    required this.snippet,
  });

  Map<String, dynamic> toMap() => {
    'source_title': sourceTitle,
    'page_number': pageNumber,
    'snippet': snippet,
  };

  factory Citation.fromMap(Map<String, dynamic> map) => Citation(
    sourceTitle: map['source_title'] as String,
    pageNumber: map['page_number'] as int,
    snippet: map['snippet'] as String,
  );
}

class NotebookMessage {
  final String id;
  final String notebookId;
  final String role; // 'user' or 'assistant'
  final String content;
  final List<Citation> citations;
  final DateTime createdAt;

  NotebookMessage({
    required this.id,
    required this.notebookId,
    required this.role,
    required this.content,
    required this.citations,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'notebook_id': notebookId,
    'role': role,
    'content': content,
    'citations_json': jsonEncode(citations.map((c) => c.toMap()).toList()),
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory NotebookMessage.fromMap(Map<String, dynamic> map) {
    List<Citation> parsedCitations = [];
    final jsonStr = map['citations_json'] as String?;
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        parsedCitations = list.map((c) => Citation.fromMap(c as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    return NotebookMessage(
      id: map['id'] as String,
      notebookId: map['notebook_id'] as String,
      role: map['role'] as String,
      content: map['content'] as String,
      citations: parsedCitations,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  NotebookMessage copyWith({String? content, List<Citation>? citations}) {
    return NotebookMessage(
      id: id,
      notebookId: notebookId,
      role: role,
      content: content ?? this.content,
      citations: citations ?? this.citations,
      createdAt: createdAt,
    );
  }
}

class DialogueLine {
  final String speaker; // "Alex" or "Sam"
  final String text;

  DialogueLine({required this.speaker, required this.text});

  Map<String, dynamic> toMap() => {'speaker': speaker, 'text': text};

  factory DialogueLine.fromMap(Map<String, dynamic> map) => DialogueLine(
    speaker: map['speaker'] as String,
    text: map['text'] as String,
  );
}

class AudioOverview {
  final String id;
  final String notebookId;
  final String title;
  final String audioPath;
  final List<DialogueLine> script;
  final DateTime createdAt;

  AudioOverview({
    required this.id,
    required this.notebookId,
    required this.title,
    required this.audioPath,
    required this.script,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'notebook_id': notebookId,
    'title': title,
    'audio_path': audioPath,
    'script_json': jsonEncode(script.map((s) => s.toMap()).toList()),
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory AudioOverview.fromMap(Map<String, dynamic> map) {
    List<DialogueLine> parsedScript = [];
    final jsonStr = map['script_json'] as String;
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      parsedScript = list.map((s) => DialogueLine.fromMap(s as Map<String, dynamic>)).toList();
    } catch (_) {}

    return AudioOverview(
      id: map['id'] as String,
      notebookId: map['notebook_id'] as String,
      title: map['title'] as String,
      audioPath: map['audio_path'] as String,
      script: parsedScript,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
