import 'dart:convert';

class StepExecutionLog {
  final String id;
  final String runId;
  final String stepId;
  final String stepName;
  final String service;
  final String status; // 'success', 'failed', 'running'
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> outputs;
  final String? errorMessage;
  final DateTime executedAt;

  StepExecutionLog({
    required this.id,
    required this.runId,
    required this.stepId,
    required this.stepName,
    required this.service,
    required this.status,
    required this.inputs,
    required this.outputs,
    this.errorMessage,
    required this.executedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'run_id': runId,
      'step_id': stepId,
      'step_name': stepName,
      'service': service,
      'status': status,
      'inputs_json': jsonEncode(inputs),
      'outputs_json': jsonEncode(outputs),
      'error_message': errorMessage,
      'executed_at': executedAt.toIso8601String(),
    };
  }

  factory StepExecutionLog.fromMap(Map<String, dynamic> map) {
    return StepExecutionLog(
      id: map['id'] as String,
      runId: map['run_id'] as String,
      stepId: map['step_id'] as String,
      stepName: map['step_name'] as String,
      service: map['service'] as String,
      status: map['status'] as String,
      inputs: Map<String, dynamic>.from(jsonDecode(map['inputs_json'] as String) as Map? ?? {}),
      outputs: Map<String, dynamic>.from(jsonDecode(map['outputs_json'] as String) as Map? ?? {}),
      errorMessage: map['error_message'] as String?,
      executedAt: DateTime.parse(map['executed_at'] as String),
    );
  }
}

class WorkflowRun {
  final String id;
  final String workflowId;
  final String workflowTitle;
  final String status; // 'pending', 'running', 'success', 'failed'
  final DateTime startedAt;
  final DateTime? finishedAt;
  final Map<String, dynamic> triggerPayload;
  final List<StepExecutionLog> stepLogs;

  WorkflowRun({
    required this.id,
    required this.workflowId,
    required this.workflowTitle,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    required this.triggerPayload,
    this.stepLogs = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workflow_id': workflowId,
      'workflow_title': workflowTitle,
      'status': status,
      'started_at': startedAt.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'trigger_payload_json': jsonEncode(triggerPayload),
    };
  }

  factory WorkflowRun.fromMap(Map<String, dynamic> map, [List<StepExecutionLog> stepLogs = const []]) {
    return WorkflowRun(
      id: map['id'] as String,
      workflowId: map['workflow_id'] as String,
      workflowTitle: map['workflow_title'] as String,
      status: map['status'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      finishedAt: map['finished_at'] != null ? DateTime.parse(map['finished_at'] as String) : null,
      triggerPayload: Map<String, dynamic>.from(jsonDecode(map['trigger_payload_json'] as String) as Map? ?? {}),
      stepLogs: stepLogs,
    );
  }

  WorkflowRun copyWith({
    String? id,
    String? workflowId,
    String? workflowTitle,
    String? status,
    DateTime? startedAt,
    DateTime? finishedAt,
    Map<String, dynamic>? triggerPayload,
    List<StepExecutionLog>? stepLogs,
  }) {
    return WorkflowRun(
      id: id ?? this.id,
      workflowId: workflowId ?? this.workflowId,
      workflowTitle: workflowTitle ?? this.workflowTitle,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      triggerPayload: triggerPayload ?? this.triggerPayload,
      stepLogs: stepLogs ?? this.stepLogs,
    );
  }
}
