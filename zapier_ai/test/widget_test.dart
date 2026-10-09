import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zapier_ai/core/engine/variable_interpolator.dart';
import 'package:zapier_ai/features/connectors/ai_connector.dart';
import 'package:zapier_ai/features/connectors/discord_connector.dart';
import 'package:zapier_ai/features/connectors/email_connector.dart';
import 'package:zapier_ai/features/connectors/http_connector.dart';
import 'package:zapier_ai/features/connectors/schedule_connector.dart';
import 'package:zapier_ai/features/connectors/slack_connector.dart';
import 'package:zapier_ai/features/generator/workflow_generator_service.dart';
import 'package:zapier_ai/features/runner/workflow_runner_service.dart';
import 'package:zapier_ai/features/workflows/models/workflow.dart';
import 'package:zapier_ai/features/workflows/models/workflow_run.dart';
import 'package:zapier_ai/features/workflows/models/workflow_step.dart';
import 'package:zapier_ai/features/workflows/workflow_repository.dart';

// Test fake repository in-memory
class FakeWorkflowRepository extends WorkflowRepository {
  final Map<String, Workflow> workflows = {};
  final List<WorkflowRun> runs = [];
  final List<StepExecutionLog> logs = [];

  @override
  Future<List<Workflow>> getAllWorkflows() async => workflows.values.toList();

  @override
  Future<void> saveWorkflow(Workflow workflow) async {
    workflows[workflow.id] = workflow;
  }

  @override
  Future<void> updateLastRun(String id, DateTime lastRun) async {
    if (workflows.containsKey(id)) {
      workflows[id] = workflows[id]!.copyWith(lastRunAt: lastRun);
    }
  }

  @override
  Future<void> saveWorkflowRun(WorkflowRun run) async {
    final idx = runs.indexWhere((r) => r.id == run.id);
    if (idx >= 0) {
      runs[idx] = run;
    } else {
      runs.add(run);
    }
  }

  @override
  Future<void> saveStepLog(StepExecutionLog log) async {
    logs.add(log);
  }

  @override
  Future<List<WorkflowRun>> getRunsForWorkflow(String workflowId) async {
    return runs.where((r) => r.workflowId == workflowId).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('VariableInterpolator Tests', () {
    test('Interpolates simple and nested variables', () {
      final context = {
        'trigger': {'sender': 'alice@company.com', 'subject': 'Urgent Bug'},
        'step_1': {'output': 'Classification: Critical'},
      };

      final res1 = VariableInterpolator.interpolate(
        'Alert from {{trigger.sender}} regarding {{trigger.subject}}: {{step_1.output}}',
        context,
      );
      expect(res1, 'Alert from alice@company.com regarding Urgent Bug: Classification: Critical');
    });

    test('Interpolates nested maps correctly', () {
      final context = {
        'step_1': {'output': 'Summary data'},
      };
      final inputMap = {
        'title': 'Report',
        'content': 'Body: {{step_1.output}}',
        'count': 42,
      };

      final resolved = VariableInterpolator.interpolateMap(inputMap, context);
      expect(resolved['title'], 'Report');
      expect(resolved['content'], 'Body: Summary data');
      expect(resolved['count'], 42);
    });
  });

  group('Workflow Models Serialization Tests', () {
    test('WorkflowStep toMap and fromMap', () {
      final step = WorkflowStep(
        id: 'step_1',
        name: 'Test Step',
        service: 'ai',
        actionName: 'summarize',
        config: {'prompt': 'Summarize {{trigger.body}}'},
        inputMappings: {'body': '{{trigger.body}}'},
      );

      final map = step.toMap();
      final restored = WorkflowStep.fromMap(map);

      expect(restored.id, 'step_1');
      expect(restored.service, 'ai');
      expect(restored.actionName, 'summarize');
      expect(restored.config['prompt'], 'Summarize {{trigger.body}}');
      expect(restored.inputMappings['body'], '{{trigger.body}}');
    });

    test('Workflow and WorkflowRun serialization roundtrip', () {
      final now = DateTime.now();
      final wf = Workflow(
        id: 'wf_123',
        title: 'Customer Triage',
        description: 'Triage customer inquiries',
        trigger: WorkflowStep(
          id: 'trig',
          name: 'Email Trigger',
          service: 'email',
          actionName: 'receive_email',
          config: {},
        ),
        actions: [
          WorkflowStep(
            id: 'act1',
            name: 'Slack Notification',
            service: 'slack',
            actionName: 'send_message',
            config: {'message': 'Hello'},
          ),
        ],
        createdAt: now,
      );

      final map = wf.toMap();
      final restored = Workflow.fromMap(map);

      expect(restored.id, 'wf_123');
      expect(restored.title, 'Customer Triage');
      expect(restored.trigger.service, 'email');
      expect(restored.actions.length, 1);
      expect(restored.actions.first.service, 'slack');
    });
  });

  group('WorkflowGeneratorService Natural Language Tests', () {
    test('Generates email trigger + AI summarize + Discord action from one sentence', () async {
      final generator = WorkflowGeneratorService();
      final wf = await generator.generateFromPrompt(
        'When I get an email from customer support, summarize it with AI and post to Discord',
      );

      expect(wf.trigger.service, 'email');
      expect(wf.actions.any((a) => a.service == 'ai'), isTrue);
      expect(wf.actions.any((a) => a.service == 'discord'), isTrue);
      expect(wf.actions.length, greaterThanOrEqualTo(2));
    });

    test('Generates schedule trigger + HTTP fetch + AI step + Slack action', () async {
      final generator = WorkflowGeneratorService();
      final wf = await generator.generateFromPrompt(
        'Every 60s fetch Bitcoin price from CoinGecko, analyze with AI, and send Slack alert',
      );

      expect(wf.trigger.service, 'schedule');
      expect(wf.actions.any((a) => a.service == 'http'), isTrue);
      expect(wf.actions.any((a) => a.service == 'ai'), isTrue);
      expect(wf.actions.any((a) => a.service == 'slack'), isTrue);
    });
  });

  group('WorkflowRunnerService Execution Tests', () {
    test('Executes multi-step workflow end-to-end with verified log generation', () async {
      final fakeRepo = FakeWorkflowRepository();
      final runner = WorkflowRunnerService(
        repository: fakeRepo,
        scheduleConnector: ScheduleConnector(),
        httpConnector: HttpConnector(),
        aiConnector: AiConnector(),
        discordConnector: DiscordConnector(),
        slackConnector: SlackConnector(),
        emailConnector: EmailConnector(),
      );

      final wf = Workflow(
        id: 'wf_exec_test',
        title: 'End to End Pipeline Test',
        description: 'Testing trigger to action chain',
        trigger: WorkflowStep(
          id: 'step_trig',
          name: 'Scheduled Trigger',
          service: 'schedule',
          actionName: 'interval',
          config: {},
        ),
        actions: [
          WorkflowStep(
            id: 'step_ai',
            name: 'AI Analysis',
            service: 'ai',
            actionName: 'classify',
            config: {
              'prompt': 'Urgent: Latency spike detected on system server at {{trigger.time}}',
            },
          ),
          WorkflowStep(
            id: 'step_discord',
            name: 'Discord Notification',
            service: 'discord',
            actionName: 'send_message',
            config: {
              'title': 'Test Alert',
              'message': 'AI assessment: {{step_ai.output}}',
            },
            inputMappings: {'message': '{{step_ai.output}}'},
          ),
          WorkflowStep(
            id: 'step_email',
            name: 'Email Confirmation',
            service: 'email',
            actionName: 'send_email',
            config: {
              'to': 'admin@test.internal',
              'subject': 'Alert Dispatched',
              'body': '{{step_discord.payload.content}}',
            },
          ),
        ],
        createdAt: DateTime.now(),
      );

      final runResult = await runner.executeWorkflow(wf);

      expect(runResult.status, 'success');
      expect(runResult.stepLogs.length, 3);
      expect(runResult.stepLogs[0].service, 'ai');
      expect(runResult.stepLogs[0].status, 'success');
      expect(runResult.stepLogs[0].outputs['output'], contains('[P1 Critical]'));

      expect(runResult.stepLogs[1].service, 'discord');
      expect(runResult.stepLogs[1].status, 'success');
      expect(runResult.stepLogs[1].outputs['delivered'], isTrue);

      expect(runResult.stepLogs[2].service, 'email');
      expect(runResult.stepLogs[2].status, 'success');
      expect(runResult.stepLogs[2].outputs['status'], 'sent');

      expect(fakeRepo.runs.length, 1);
      expect(fakeRepo.logs.length, 3);
    });
  });
}
