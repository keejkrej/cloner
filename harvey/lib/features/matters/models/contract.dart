import 'clause.dart';

class Contract {
  final String id;
  final String matterId;
  final String title;
  final String filePath;
  final int pageCount;
  final String rawText;
  final List<Clause> clauses;
  final int createdAt;

  const Contract({
    required this.id,
    required this.matterId,
    required this.title,
    required this.filePath,
    required this.pageCount,
    required this.rawText,
    this.clauses = const [],
    required this.createdAt,
  });

  Contract copyWith({
    String? id,
    String? matterId,
    String? title,
    String? filePath,
    int? pageCount,
    String? rawText,
    List<Clause>? clauses,
    int? createdAt,
  }) {
    return Contract(
      id: id ?? this.id,
      matterId: matterId ?? this.matterId,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      pageCount: pageCount ?? this.pageCount,
      rawText: rawText ?? this.rawText,
      clauses: clauses ?? this.clauses,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matter_id': matterId,
      'title': title,
      'file_path': filePath,
      'page_count': pageCount,
      'raw_text': rawText,
      'created_at': createdAt,
    };
  }

  factory Contract.fromMap(Map<String, dynamic> map, {List<Clause> clauses = const []}) {
    return Contract(
      id: map['id'] as String,
      matterId: map['matter_id'] as String,
      title: map['title'] as String,
      filePath: map['file_path'] as String,
      pageCount: map['page_count'] as int,
      rawText: map['raw_text'] as String,
      clauses: clauses,
      createdAt: map['created_at'] as int,
    );
  }
}
