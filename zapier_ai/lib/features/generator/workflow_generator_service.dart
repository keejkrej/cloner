import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../core/settings/settings_service.dart';
import '../workflows/models/workflow.dart';
import '../workflows/models/workflow_step.dart';

class WorkflowGeneratorService {
  final SettingsService _settingsService;
  final http.Client? client;

  WorkflowGeneratorService({SettingsService? settingsService, this.client})
      : _settingsService = settingsService ?? SettingsService();

  Future<Workflow> generateFromPrompt(String prompt) async {
    final openAiKey = await _settingsService.getOpenAiKey();

    if (openAiKey != null && openAiKey.trim().isNotEmpty) {
      try {
        final httpClient = client ?? http.Client();
        final res = await httpClient.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $openAiKey',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'messages': [
              {
                'role': 'system',
                'content': '''You are an expert Zapier workflow architect. Convert the user's natural language automation request into a valid JSON workflow object.
Services available: 'schedule', 'http', 'email', 'discord', 'slack', 'ai'.
Rules:
1. Root must be JSON with: "title" (string), "description" (string), "trigger" (object), "actions" (array of objects).
2. Each step must have: "id" (string), "name" (string), "service" (one of schedule, http, email, discord, slack, ai), "actionName" (string), "config" (map of parameters), "inputMappings" (map of variable paths).
3. Connect outputs from prior steps using {{trigger.field}} or {{step_id.field}} or {{step_id.output}}.
4. Return ONLY valid JSON, no markdown backticks or explanation.
'''
              },
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.2,
          }),
        ).timeout(const Duration(seconds: 25));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          var content = data['choices'][0]['message']['content'] as String;
          content = content.replaceAll('```json', '').replaceAll('```', '').trim();
          final parsed = jsonDecode(content) as Map<String, dynamic>;

          final uuid = const Uuid();
          final triggerMap = parsed['trigger'] as Map<String, dynamic>;
          final actionsList = parsed['actions'] as List;

          final trigger = WorkflowStep(
            id: triggerMap['id'] ?? 'trigger_${uuid.v4().substring(0, 8)}',
            name: triggerMap['name'] ?? 'Trigger Step',
            service: triggerMap['service'] ?? 'schedule',
            actionName: triggerMap['actionName'] ?? 'event',
            config: Map<String, dynamic>.from(triggerMap['config'] as Map? ?? {}),
            inputMappings: Map<String, String>.from(triggerMap['inputMappings'] as Map? ?? {}),
          );

          final actions = actionsList.map((a) {
            final aMap = a as Map<String, dynamic>;
            return WorkflowStep(
              id: aMap['id'] ?? 'action_${uuid.v4().substring(0, 8)}',
              name: aMap['name'] ?? 'Action Step',
              service: aMap['service'] ?? 'http',
              actionName: aMap['actionName'] ?? 'execute',
              config: Map<String, dynamic>.from(aMap['config'] as Map? ?? {}),
              inputMappings: Map<String, String>.from(aMap['inputMappings'] as Map? ?? {}),
            );
          }).toList();

          return Workflow(
            id: uuid.v4(),
            title: parsed['title'] ?? 'Generated Zapier Workflow',
            description: parsed['description'] ?? prompt,
            trigger: trigger,
            actions: actions,
            createdAt: DateTime.now(),
          );
        }
      } catch (_) {
        // Fall back to rule-based parser
      }
    }

    // High quality rule-based NLP intent generator
    return _generateRuleBasedWorkflow(prompt);
  }

  Workflow _generateRuleBasedWorkflow(String prompt) {
    final uuid = const Uuid();
    final lower = prompt.toLowerCase();

    // 1. Determine Trigger
    WorkflowStep trigger;
    if (lower.contains('email') || lower.contains('mail') || lower.contains('gmail') || lower.contains('inbox')) {
      trigger = WorkflowStep(
        id: 'step_trigger',
        name: 'New Inbound Email',
        service: 'email',
        actionName: 'receive_email',
        config: {
          'sample_sender': 'client@acme.com',
          'sample_subject': 'Important project deliverable update',
          'sample_body': 'Attached is our revised project schedule for Q3. Please confirm receipt and adjust milestones.',
        },
      );
    } else if (lower.contains('every') || lower.contains('hourly') || lower.contains('daily') || lower.contains('schedule') || lower.contains('minute')) {
      int interval = 60;
      if (lower.contains('30 second') || lower.contains('30s')) interval = 30;
      if (lower.contains('minute')) interval = 60;
      if (lower.contains('hour')) interval = 3600;
      if (lower.contains('day') || lower.contains('daily')) interval = 86400;

      trigger = WorkflowStep(
        id: 'step_trigger',
        name: 'Scheduled Timer (${interval}s)',
        service: 'schedule',
        actionName: 'interval',
        config: {'interval_seconds': interval, 'cron': '*/${(interval ~/ 60).clamp(1, 60)} * * * *'},
      );
    } else {
      trigger = WorkflowStep(
        id: 'step_trigger',
        name: 'Webhook Event Listener',
        service: 'http',
        actionName: 'webhook',
        config: {
          'sample_payload': {'event': 'custom_event', 'message': prompt, 'timestamp': DateTime.now().toIso8601String()},
        },
      );
    }

    // 2. Determine Actions Sequence
    final actions = <WorkflowStep>[];

    // If HTTP / API fetch is mentioned or schedule needs data
    if (lower.contains('weather') || lower.contains('api') || lower.contains('fetch') || lower.contains('http') || lower.contains('bitcoin') || lower.contains('crypto') || lower.contains('price')) {
      String url = 'https://httpbin.org/get';
      String name = 'Fetch API Payload';
      if (lower.contains('bitcoin') || lower.contains('crypto') || lower.contains('price')) {
        url = 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd&include_24hr_change=true';
        name = 'Fetch CoinGecko Price';
      } else if (lower.contains('weather')) {
        url = 'https://api.open-meteo.com/v1/forecast?latitude=40.7128&longitude=-74.0060&current=temperature_2m,wind_speed_10m';
        name = 'Query Weather API';
      }
      actions.add(WorkflowStep(
        id: 'step_fetch',
        name: name,
        service: 'http',
        actionName: 'request',
        config: {'method': 'GET', 'url': url},
      ));
    }

    // AI Step
    if (lower.contains('summar') || lower.contains('ai') || lower.contains('analyz') || lower.contains('extract') || lower.contains('triage') || lower.contains('sentiment') || lower.contains('translate') || actions.isEmpty) {
      String prevRef = actions.isNotEmpty ? '{{step_fetch.body}}' : (trigger.service == 'email' ? '{{step_trigger.body}}' : '{{step_trigger.event}}');
      actions.add(WorkflowStep(
        id: 'step_ai',
        name: 'AI Analysis & Synthesis',
        service: 'ai',
        actionName: 'summarize',
        config: {
          'prompt': 'Analyze and extract concise actionable key points from: $prevRef.',
        },
        inputMappings: {'input_data': prevRef},
      ));
    }

    // Destination: Discord, Slack, Email, or Webhook
    final lastStepId = actions.isNotEmpty ? actions.last.id : trigger.id;
    final lastOutputRef = '{{$lastStepId.output}}';

    if (lower.contains('discord')) {
      actions.add(WorkflowStep(
        id: 'step_discord',
        name: 'Post to Discord Channel',
        service: 'discord',
        actionName: 'send_message',
        config: {
          'title': '⚡ Automated Zapier Workflow Update',
          'message': lastOutputRef,
          'color': 5814783,
        },
        inputMappings: {'message': lastOutputRef},
      ));
    }

    if (lower.contains('slack')) {
      actions.add(WorkflowStep(
        id: 'step_slack',
        name: 'Send Slack Notification',
        service: 'slack',
        actionName: 'send_message',
        config: {
          'channel': '#automation-feed',
          'message': '🚀 *Workflow Event Alert*\n$lastOutputRef',
        },
        inputMappings: {'message': lastOutputRef},
      ));
    }

    if (lower.contains('send email') || (lower.contains('email') && !lower.contains('when i get an email') && !lower.contains('receive email'))) {
      actions.add(WorkflowStep(
        id: 'step_email_send',
        name: 'Send Digest Email',
        service: 'email',
        actionName: 'send_email',
        config: {
          'to': 'team@company.internal',
          'subject': 'Daily Automated Briefing',
          'body': lastOutputRef,
        },
        inputMappings: {'body': lastOutputRef},
      ));
    }

    // If no destination was caught, default to Discord or HTTP
    if (!actions.any((a) => a.service == 'discord' || a.service == 'slack' || a.service == 'email')) {
      actions.add(WorkflowStep(
        id: 'step_discord_default',
        name: 'Post to Discord Notification Feed',
        service: 'discord',
        actionName: 'send_message',
        config: {
          'title': 'Automated Workflow Output',
          'message': lastOutputRef,
        },
        inputMappings: {'message': lastOutputRef},
      ));
    }

    // Title generation
    String title = prompt.trim();
    if (title.length > 50) {
      title = '${title.substring(0, 47)}...';
    }
    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }

    return Workflow(
      id: uuid.v4(),
      title: title,
      description: prompt,
      trigger: trigger,
      actions: actions,
      createdAt: DateTime.now(),
    );
  }
}
