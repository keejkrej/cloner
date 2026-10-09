import '../workflows/models/workflow_step.dart';

abstract class Connector {
  String get serviceId; // 'schedule', 'http', 'email', 'discord', 'slack', 'ai'
  String get displayName;
  String get iconName;

  /// Executes an action step with interpolated inputs
  Future<Map<String, dynamic>> executeAction(
    WorkflowStep step,
    Map<String, dynamic> resolvedConfig,
    Map<String, dynamic> executionContext,
  );

  /// Generates trigger payload when a trigger fires
  Future<Map<String, dynamic>> evaluateTrigger(
    WorkflowStep triggerStep,
  ) async {
    return {'triggered_at': DateTime.now().toIso8601String()};
  }
}
