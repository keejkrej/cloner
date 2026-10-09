import 'dart:convert';
import 'workflow_step.dart';

class Workflow {
  final String id;
  final String title;
  final String description;
  final bool isActive;
  final WorkflowStep trigger;
  final List<WorkflowStep> actions;
  final DateTime createdAt;
  final DateTime? lastRunAt;

  Workflow({
    required this.id,
    required this.title,
    required this.description,
    this.isActive = true,
    required this.trigger,
    required this.actions,
    required this.createdAt,
    this.lastRunAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'trigger_json': jsonEncode(trigger.toMap()),
      'actions_json': jsonEncode(actions.map((a) => a.toMap()).toList()),
      'created_at': createdAt.toIso8601String(),
      'last_run_at': lastRunAt?.toIso8601String(),
    };
  }

  factory Workflow.fromMap(Map<String, dynamic> map) {
    return Workflow(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      isActive: (map['is_active'] as int) == 1,
      trigger: WorkflowStep.fromMap(jsonDecode(map['trigger_json'] as String) as Map<String, dynamic>),
      actions: (jsonDecode(map['actions_json'] as String) as List)
          .map((a) => WorkflowStep.fromMap(a as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
      lastRunAt: map['last_run_at'] != null ? DateTime.parse(map['last_run_at'] as String) : null,
    );
  }

  Workflow copyWith({
    String? id,
    String? title,
    String? description,
    bool? isActive,
    WorkflowStep? trigger,
    List<WorkflowStep>? actions,
    DateTime? createdAt,
    DateTime? lastRunAt,
  }) {
    return Workflow(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      trigger: trigger ?? this.trigger,
      actions: actions ?? this.actions,
      createdAt: createdAt ?? this.createdAt,
      lastRunAt: lastRunAt ?? this.lastRunAt,
    );
  }
}
