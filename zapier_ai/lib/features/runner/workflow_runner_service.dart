import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/engine/variable_interpolator.dart';
import '../connectors/ai_connector.dart';
import '../connectors/connector.dart';
import '../connectors/discord_connector.dart';
import '../connectors/email_connector.dart';
import '../connectors/http_connector.dart';
import '../connectors/schedule_connector.dart';
import '../connectors/slack_connector.dart';
import '../workflows/models/workflow.dart';
import '../workflows/models/workflow_run.dart';
import '../workflows/workflow_repository.dart';

class WorkflowRunnerService {
  final WorkflowRepository _repository;
  final Map<String, Connector> _connectors = {};
  Timer? _schedulerTimer;
  final _runUpdateController = StreamController<WorkflowRun>.broadcast();

  Stream<WorkflowRun> get onRunUpdated => _runUpdateController.stream;

  WorkflowRunnerService({
    WorkflowRepository? repository,
    HttpConnector? httpConnector,
    AiConnector? aiConnector,
    DiscordConnector? discordConnector,
    SlackConnector? slackConnector,
    EmailConnector? emailConnector,
    ScheduleConnector? scheduleConnector,
  }) : _repository = repository ?? WorkflowRepository() {
    _registerConnector(scheduleConnector ?? ScheduleConnector());
    _registerConnector(httpConnector ?? HttpConnector());
    _registerConnector(aiConnector ?? AiConnector());
    _registerConnector(discordConnector ?? DiscordConnector());
    _registerConnector(slackConnector ?? SlackConnector());
    _registerConnector(emailConnector ?? EmailConnector());
  }

  void _registerConnector(Connector connector) {
    _connectors[connector.serviceId] = connector;
  }

  Connector? getConnector(String serviceId) => _connectors[serviceId];

  void startScheduler({Duration pollInterval = const Duration(seconds: 15)}) {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(pollInterval, (timer) async {
      await _checkAndTriggerScheduledWorkflows();
    });
  }

  void stopScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
  }

  void dispose() {
    stopScheduler();
    _runUpdateController.close();
  }

  Future<void> _checkAndTriggerScheduledWorkflows() async {
    try {
      final workflows = await _repository.getAllWorkflows();
      final now = DateTime.now();

      for (final wf in workflows) {
        if (!wf.isActive) continue;

        // Check if trigger is schedule
        if (wf.trigger.service == 'schedule') {
          final intervalSec = (wf.trigger.config['interval_seconds'] as num?)?.toInt() ?? 60;
          final lastRun = wf.lastRunAt;

          final shouldRun = lastRun == null || now.difference(lastRun).inSeconds >= intervalSec;
          if (shouldRun) {
            // Trigger automatic scheduled execution
            await executeWorkflow(wf, isAutomatic: true);
          }
        }
      }
    } catch (_) {
      // Ignore background ticker errors
    }
  }

  Future<WorkflowRun> executeWorkflow(Workflow workflow, {bool isAutomatic = false}) async {
    final uuid = const Uuid();
    final runId = uuid.v4();
    final now = DateTime.now();

    // 1. Evaluate Trigger
    final triggerConnector = _connectors[workflow.trigger.service] ?? ScheduleConnector();
    final triggerPayload = await triggerConnector.evaluateTrigger(workflow.trigger);

    var currentRun = WorkflowRun(
      id: runId,
      workflowId: workflow.id,
      workflowTitle: workflow.title,
      status: 'running',
      startedAt: now,
      triggerPayload: triggerPayload,
      stepLogs: [],
    );

    await _repository.saveWorkflowRun(currentRun);
    _runUpdateController.add(currentRun);

    final context = <String, dynamic>{
      'trigger': triggerPayload,
    };

    final stepLogs = <StepExecutionLog>[];
    bool hasFailure = false;

    // 2. Execute Action Pipeline
    for (final action in workflow.actions) {
      final stepId = action.id;
      final connector = _connectors[action.service];

      if (connector == null) {
        final errorLog = StepExecutionLog(
          id: uuid.v4(),
          runId: runId,
          stepId: stepId,
          stepName: action.name,
          service: action.service,
          status: 'failed',
          inputs: {},
          outputs: {},
          errorMessage: 'Unknown connector service: ${action.service}',
          executedAt: DateTime.now(),
        );
        stepLogs.add(errorLog);
        await _repository.saveStepLog(errorLog);
        hasFailure = true;
        break;
      }

      // Interpolate config placeholders using current execution context
      final resolvedConfig = VariableInterpolator.interpolateMap(action.config, context);

      final inputsRecord = Map<String, dynamic>.from(resolvedConfig);
      for (final mapping in action.inputMappings.entries) {
        inputsRecord[mapping.key] = VariableInterpolator.interpolate(mapping.value, context);
      }

      try {
        final stepOutput = await connector.executeAction(action, resolvedConfig, context);

        // Put step outputs into context for subsequent steps
        context[stepId] = stepOutput;
        // Also provide generic last_step alias
        context['last_step'] = stepOutput;

        final successLog = StepExecutionLog(
          id: uuid.v4(),
          runId: runId,
          stepId: stepId,
          stepName: action.name,
          service: action.service,
          status: 'success',
          inputs: inputsRecord,
          outputs: stepOutput,
          executedAt: DateTime.now(),
        );

        stepLogs.add(successLog);
        await _repository.saveStepLog(successLog);

        currentRun = currentRun.copyWith(stepLogs: List.from(stepLogs));
        _runUpdateController.add(currentRun);
      } catch (e) {
        final errorLog = StepExecutionLog(
          id: uuid.v4(),
          runId: runId,
          stepId: stepId,
          stepName: action.name,
          service: action.service,
          status: 'failed',
          inputs: inputsRecord,
          outputs: {},
          errorMessage: e.toString(),
          executedAt: DateTime.now(),
        );

        stepLogs.add(errorLog);
        await _repository.saveStepLog(errorLog);
        hasFailure = true;
        break;
      }
    }

    // 3. Finalize Run
    final finishedRun = currentRun.copyWith(
      status: hasFailure ? 'failed' : 'success',
      finishedAt: DateTime.now(),
      stepLogs: stepLogs,
    );

    await _repository.saveWorkflowRun(finishedRun);
    await _repository.updateLastRun(workflow.id, finishedRun.finishedAt ?? DateTime.now());
    _runUpdateController.add(finishedRun);

    return finishedRun;
  }
}
