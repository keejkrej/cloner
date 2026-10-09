import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/settings/settings_service.dart';
import 'connector.dart';
import '../workflows/models/workflow_step.dart';

class SlackConnector extends Connector {
  final SettingsService _settingsService;
  final http.Client? client;

  SlackConnector({SettingsService? settingsService, this.client})
      : _settingsService = settingsService ?? SettingsService();

  @override
  String get serviceId => 'slack';

  @override
  String get displayName => 'Slack Webhook';

  @override
  String get iconName => 'chat';

  @override
  Future<Map<String, dynamic>> executeAction(
    WorkflowStep step,
    Map<String, dynamic> resolvedConfig,
    Map<String, dynamic> executionContext,
  ) async {
    final configuredUrl = await _settingsService.getSlackWebhook();
    final webhookUrl = (resolvedConfig['webhook_url'] as String?)?.isNotEmpty == true
        ? resolvedConfig['webhook_url'] as String
        : configuredUrl;

    final channel = resolvedConfig['channel'] as String? ?? '#general';
    final message = resolvedConfig['message'] as String? ?? 'Automated alert from Zapier AI';

    final payload = {
      'channel': channel,
      'text': message,
      'blocks': [
        {
          'type': 'section',
          'text': {'type': 'mrkdwn', 'text': message},
        }
      ],
    };

    if (webhookUrl != null && webhookUrl.trim().startsWith('http')) {
      final httpClient = client ?? http.Client();
      try {
        final res = await httpClient.post(
          Uri.parse(webhookUrl.trim()),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 15));

        return {
          'status_code': res.statusCode,
          'delivered': res.statusCode >= 200 && res.statusCode < 300,
          'webhook_url': webhookUrl,
          'payload': payload,
        };
      } catch (e) {
        return {
          'status_code': 500,
          'delivered': false,
          'error': e.toString(),
          'payload': payload,
        };
      }
    }

    return {
      'status_code': 200,
      'delivered': true,
      'simulated': true,
      'channel': channel,
      'notice': 'Slack notification formatted. Add Slack Webhook URL in Settings for external delivery.',
      'payload': payload,
    };
  }
}
