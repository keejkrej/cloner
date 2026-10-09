class WorkflowStep {
  final String id;
  final String name;
  final String service; // 'schedule', 'http', 'email', 'discord', 'slack', 'ai'
  final String actionName; // e.g. 'interval', 'request', 'summarize', 'send_message'
  final Map<String, dynamic> config;
  final Map<String, String> inputMappings;

  WorkflowStep({
    required this.id,
    required this.name,
    required this.service,
    required this.actionName,
    required this.config,
    this.inputMappings = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'service': service,
      'actionName': actionName,
      'config': config,
      'inputMappings': inputMappings,
    };
  }

  factory WorkflowStep.fromMap(Map<String, dynamic> map) {
    return WorkflowStep(
      id: map['id'] as String,
      name: map['name'] as String,
      service: map['service'] as String,
      actionName: map['actionName'] as String,
      config: Map<String, dynamic>.from(map['config'] as Map? ?? {}),
      inputMappings: Map<String, String>.from(map['inputMappings'] as Map? ?? {}),
    );
  }

  WorkflowStep copyWith({
    String? id,
    String? name,
    String? service,
    String? actionName,
    Map<String, dynamic>? config,
    Map<String, String>? inputMappings,
  }) {
    return WorkflowStep(
      id: id ?? this.id,
      name: name ?? this.name,
      service: service ?? this.service,
      actionName: actionName ?? this.actionName,
      config: config ?? this.config,
      inputMappings: inputMappings ?? this.inputMappings,
    );
  }
}
