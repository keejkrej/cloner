import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/database_service.dart';
import 'models/workflow.dart';
import 'models/workflow_run.dart';
import 'models/workflow_step.dart';

class WorkflowRepository {
  final DatabaseService _dbService;

  WorkflowRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  Future<List<Workflow>> getAllWorkflows() async {
    final db = await _dbService.database;
    final results = await db.query('workflows', orderBy: 'created_at DESC');

    if (results.isEmpty) {
      await seedDefaultWorkflows();
      final seeded = await db.query('workflows', orderBy: 'created_at DESC');
      return seeded.map((map) => Workflow.fromMap(map)).toList();
    }

    return results.map((map) => Workflow.fromMap(map)).toList();
  }

  Future<Workflow?> getWorkflowById(String id) async {
    final db = await _dbService.database;
    final results = await db.query('workflows', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Workflow.fromMap(results.first);
  }

  Future<void> saveWorkflow(Workflow workflow) async {
    final db = await _dbService.database;
    await db.insert(
      'workflows',
      workflow.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateWorkflowStatus(String id, bool isActive) async {
    final db = await _dbService.database;
    await db.update(
      'workflows',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateLastRun(String id, DateTime lastRun) async {
    final db = await _dbService.database;
    await db.update(
      'workflows',
      {'last_run_at': lastRun.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteWorkflow(String id) async {
    final db = await _dbService.database;
    await db.delete('workflows', where: 'id = ?', whereArgs: [id]);
  }

  // --- Runs and Logs ---

  Future<void> saveWorkflowRun(WorkflowRun run) async {
    final db = await _dbService.database;
    await db.insert('workflow_runs', run.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveStepLog(StepExecutionLog stepLog) async {
    final db = await _dbService.database;
    await db.insert('step_logs', stepLog.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<WorkflowRun>> getRunsForWorkflow(String workflowId) async {
    final db = await _dbService.database;
    final runResults = await db.query(
      'workflow_runs',
      where: 'workflow_id = ?',
      whereArgs: [workflowId],
      orderBy: 'started_at DESC',
      limit: 30,
    );

    final runs = <WorkflowRun>[];
    for (final runMap in runResults) {
      final runId = runMap['id'] as String;
      final stepResults = await db.query(
        'step_logs',
        where: 'run_id = ?',
        whereArgs: [runId],
        orderBy: 'executed_at ASC',
      );
      final steps = stepResults.map((s) => StepExecutionLog.fromMap(s)).toList();
      runs.add(WorkflowRun.fromMap(runMap, steps));
    }
    return runs;
  }

  Future<List<WorkflowRun>> getRecentRuns({int limit = 50}) async {
    final db = await _dbService.database;
    final runResults = await db.query(
      'workflow_runs',
      orderBy: 'started_at DESC',
      limit: limit,
    );

    final runs = <WorkflowRun>[];
    for (final runMap in runResults) {
      final runId = runMap['id'] as String;
      final stepResults = await db.query(
        'step_logs',
        where: 'run_id = ?',
        whereArgs: [runId],
        orderBy: 'executed_at ASC',
      );
      final steps = stepResults.map((s) => StepExecutionLog.fromMap(s)).toList();
      runs.add(WorkflowRun.fromMap(runMap, steps));
    }
    return runs;
  }

  Future<void> seedDefaultWorkflows() async {
    final uuid = const Uuid();
    final now = DateTime.now();

    // 1. Crypto Market Pulse
    final wf1 = Workflow(
      id: uuid.v4(),
      title: 'Crypto Market Pulse',
      description: 'Fetches Bitcoin price hourly via CoinGecko, generates AI sentiment summary, and notifies Discord',
      isActive: true,
      trigger: WorkflowStep(
        id: 'step_trigger_1',
        name: 'Every 60 Seconds Timer',
        service: 'schedule',
        actionName: 'interval',
        config: {'interval_seconds': 60, 'cron': '*/1 * * * *'},
      ),
      actions: [
        WorkflowStep(
          id: 'step_action_1_1',
          name: 'Fetch CoinGecko Ticker',
          service: 'http',
          actionName: 'request',
          config: {
            'method': 'GET',
            'url': 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd&include_24hr_change=true',
            'headers': {'Accept': 'application/json'},
          },
        ),
        WorkflowStep(
          id: 'step_action_1_2',
          name: 'Analyze Market Dynamics',
          service: 'ai',
          actionName: 'transform',
          config: {
            'prompt': 'Analyze this crypto pricing payload: {{step_action_1_1.body}}. Formulate a 2-sentence market pulse update highlighting BTC & ETH 24h change.',
          },
          inputMappings: {'data': '{{step_action_1_1.body}}'},
        ),
        WorkflowStep(
          id: 'step_action_1_3',
          name: 'Post to Discord Feed',
          service: 'discord',
          actionName: 'send_message',
          config: {
            'title': '⚡ Crypto Market Pulse',
            'message': '{{step_action_1_2.output}}',
            'color': 5814783,
          },
          inputMappings: {'message': '{{step_action_1_2.output}}'},
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 2)),
    );

    // 2. Support Ticket Triage
    final wf2 = Workflow(
      id: uuid.v4(),
      title: 'Support Email Triage & Incident Alert',
      description: 'Incoming customer request → AI extracts priority & urgency → posts Slack incident alert & calls Webhook',
      isActive: true,
      trigger: WorkflowStep(
        id: 'step_trigger_2',
        name: 'New Support Email',
        service: 'email',
        actionName: 'receive_email',
        config: {
          'filter_subject': 'Support',
          'sample_sender': 'customer@enterprise.io',
          'sample_subject': 'URGENT: Production database latency spike on US-East',
          'sample_body': 'Our team is observing 4500ms API response times across client dashboards. We need urgent escalation.',
        },
      ),
      actions: [
        WorkflowStep(
          id: 'step_action_2_1',
          name: 'AI Priority & Sentiment Triage',
          service: 'ai',
          actionName: 'classify',
          config: {
            'prompt': 'Classify urgency (P1/P2/P3) and extract 1-line key issue for: Subject: {{trigger.sample_subject}}, Body: {{trigger.sample_body}}.',
          },
          inputMappings: {
            'subject': '{{trigger.sample_subject}}',
            'body': '{{trigger.sample_body}}',
          },
        ),
        WorkflowStep(
          id: 'step_action_2_2',
          name: 'Send Urgent Slack Alert',
          service: 'slack',
          actionName: 'send_message',
          config: {
            'channel': '#support-escalations',
            'message': '🚨 *New Triage Alert*\n*Sender:* {{trigger.sample_sender}}\n*AI Assessment:* {{step_action_2_1.output}}',
          },
          inputMappings: {'assessment': '{{step_action_2_1.output}}'},
        ),
        WorkflowStep(
          id: 'step_action_2_3',
          name: 'Sync to Internal Webhook',
          service: 'http',
          actionName: 'request',
          config: {
            'method': 'POST',
            'url': 'https://httpbin.org/post',
            'body': '{"status":"triaged","sender":"{{trigger.sample_sender}}","analysis":"{{step_action_2_1.output}}"}',
          },
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 1)),
    );

    // 3. Daily Weather Brief
    final wf3 = Workflow(
      id: uuid.v4(),
      title: 'Executive Morning Brief',
      description: 'Daily schedule → queries Open-Meteo weather API → AI formats briefing → sends Email digest',
      isActive: false,
      trigger: WorkflowStep(
        id: 'step_trigger_3',
        name: 'Daily at 8:00 AM',
        service: 'schedule',
        actionName: 'schedule',
        config: {'cron': '0 8 * * *', 'interval_seconds': 86400},
      ),
      actions: [
        WorkflowStep(
          id: 'step_action_3_1',
          name: 'Get Current Weather Data',
          service: 'http',
          actionName: 'request',
          config: {
            'method': 'GET',
            'url': 'https://api.open-meteo.com/v1/forecast?latitude=37.7749&longitude=-122.4194&current=temperature_2m,wind_speed_10m',
          },
        ),
        WorkflowStep(
          id: 'step_action_3_2',
          name: 'Synthesize Daily Executive Brief',
          service: 'ai',
          actionName: 'transform',
          config: {
            'prompt': 'Write an energetic 2-paragraph morning executive brief given this weather payload: {{step_action_3_1.body}}.',
          },
        ),
        WorkflowStep(
          id: 'step_action_3_3',
          name: 'Dispatch Morning Email',
          service: 'email',
          actionName: 'send_email',
          config: {
            'to': 'executive@acme.corp',
            'subject': '☀️ Your Daily Executive Morning Brief',
            'body': '{{step_action_3_2.output}}',
          },
        ),
      ],
      createdAt: now.subtract(const Duration(minutes: 30)),
    );

    await saveWorkflow(wf1);
    await saveWorkflow(wf2);
    await saveWorkflow(wf3);
  }
}
