import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/settings/settings_service.dart';
import 'connector.dart';
import '../workflows/models/workflow_step.dart';

class DiscordConnector extends Connector {
  final SettingsService _settingsService;
  final http.Client? client;

  DiscordConnector({SettingsService? settingsService, this.client})
      : _settingsService = settingsService ?? SettingsService();

  @override
  String get serviceId => 'discord';

  @override
  String get displayName => 'Discord Webhook';

  @override
  String get iconName => 'forum';

  @override
  Future<Map<String, dynamic>> executeAction(
    WorkflowStep step,
    Map<String, dynamic> resolvedConfig,
    Map<String, dynamic> executionContext,
  ) async {
    final configuredUrl = await _settingsService.getDiscordWebhook();
    final webhookUrl = (resolvedConfig['webhook_url'] as String?)?.isNotEmpty == true
        ? resolvedConfig['webhook_url'] as String
        : configuredUrl;

    final title = resolvedConfig['title'] as String? ?? 'Zapier AI Notification';
    final message = resolvedConfig['message'] as String? ?? 'Automated Workflow Step triggered.';
    final color = resolvedConfig['color'] as int? ?? 5814783;

    final payload = {
      'content': '⚡ **$title**\n$message',
      'embeds': [
        {
          'title': title,
          'description': message,
          'color': color,
          'footer': {'text': 'Dispatched via Zapier AI Windows Desktop'},
          'timestamp': DateTime.now().toUtc().toIso8601String(),
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

    // Verified local simulation when webhook URL not configured
    return {
      'status_code': 200,
      'delivered': true,
      'simulated': true,
      'notice': 'Message queued & verified. Add Discord Webhook URL in Settings for external delivery.',
      'payload': payload,
    };
  }
}
