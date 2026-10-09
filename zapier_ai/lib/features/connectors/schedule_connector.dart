import 'connector.dart';
import '../workflows/models/workflow_step.dart';

class ScheduleConnector extends Connector {
  @override
  String get serviceId => 'schedule';

  @override
  String get displayName => 'Schedule by Zapier';

  @override
  String get iconName => 'schedule';

  @override
  Future<Map<String, dynamic>> evaluateTrigger(WorkflowStep triggerStep) async {
    final now = DateTime.now();
    return {
      'timestamp': now.toIso8601String(),
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
      'day_of_week': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][now.weekday - 1],
    };
  }

  @override
  Future<Map<String, dynamic>> executeAction(
    WorkflowStep step,
    Map<String, dynamic> resolvedConfig,
    Map<String, dynamic> executionContext,
  ) async {
    // Schedule as an action step (e.g. delay)
    final delaySeconds = (resolvedConfig['delay_seconds'] as num?)?.toInt() ?? 1;
    await Future.delayed(Duration(seconds: delaySeconds));
    return {
      'delayed_seconds': delaySeconds,
      'completed_at': DateTime.now().toIso8601String(),
    };
  }
}
