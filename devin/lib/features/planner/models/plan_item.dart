enum PlanItemStatus { pending, inProgress, completed, failed }

class PlanItem {
  final String id;
  final String title;
  final String description;
  final PlanItemStatus status;
  final String? tool;
  final String? output;

  PlanItem({
    required this.id,
    required this.title,
    required this.description,
    this.status = PlanItemStatus.pending,
    this.tool,
    this.output,
  });

  PlanItem copyWith({
    String? id,
    String? title,
    String? description,
    PlanItemStatus? status,
    String? tool,
    String? output,
  }) {
    return PlanItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      tool: tool ?? this.tool,
      output: output ?? this.output,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'tool': tool,
      'output': output,
    };
  }

  factory PlanItem.fromMap(Map<String, dynamic> map) {
    return PlanItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      status: PlanItemStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PlanItemStatus.pending,
      ),
      tool: map['tool'] as String?,
      output: map['output'] as String?,
    );
  }
}
