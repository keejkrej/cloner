abstract class SiriTool {
  String get name;
  String get description;
  Map<String, dynamic> get parametersSchema;

  Future<ToolExecutionResult> execute(Map<String, dynamic> arguments);
}

class ToolExecutionResult {
  final bool success;
  final String speechResponse;
  final String displayText;
  final String? toolType; // 'weather', 'timer', 'app', 'system', 'url'
  final Map<String, dynamic> data;

  ToolExecutionResult({
    required this.success,
    required this.speechResponse,
    required this.displayText,
    this.toolType,
    this.data = const {},
  });
}
