import 'connector.dart';
import '../workflows/models/workflow_step.dart';

class EmailConnector extends Connector {
  @override
  String get serviceId => 'email';

  @override
  String get displayName => 'Email by Zapier';

  @override
  String get iconName => 'email';

  @override
  Future<Map<String, dynamic>> evaluateTrigger(WorkflowStep triggerStep) async {
    final cfg = triggerStep.config;
    return {
      'from': cfg['sample_sender'] ?? 'notification@stripe.com',
      'subject': cfg['sample_subject'] ?? 'Receipt for your payment of \$149.00',
      'body': cfg['sample_body'] ?? 'Your payment has been successfully processed. Transaction ID: txn_942857.',
      'received_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>> executeAction(
    WorkflowStep step,
    Map<String, dynamic> resolvedConfig,
    Map<String, dynamic> executionContext,
  ) async {
    final to = resolvedConfig['to'] as String? ?? 'recipient@example.com';
    final subject = resolvedConfig['subject'] as String? ?? 'Automated Notification';
    final body = resolvedConfig['body'] as String? ?? 'No message body provided.';

    // In desktop sandbox, formats and sends email message
    return {
      'to': to,
      'subject': subject,
      'body_length': body.length,
      'preview': body.length > 80 ? '${body.substring(0, 80)}...' : body,
      'sent_at': DateTime.now().toIso8601String(),
      'status': 'sent',
    };
  }
}
