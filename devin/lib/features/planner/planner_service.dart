import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../core/settings/settings_service.dart';
import 'models/plan_item.dart';

class PlannerService {
  final SettingsService _settingsService;
  final http.Client? client;

  PlannerService({SettingsService? settingsService, this.client})
      : _settingsService = settingsService ?? SettingsService();

  Future<List<PlanItem>> generatePlan(String taskPrompt, String repoPath) async {
    final apiKey = await _settingsService.getOpenAiKey();

    if (apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        final httpClient = client ?? http.Client();
        final res = await httpClient.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'messages': [
              {
                'role': 'system',
                'content': '''You are Devin, the autonomous AI software engineer. Break down the user's coding task into 4 to 6 logical sequential milestones.
Return a JSON array of objects with keys:
"title" (short milestone title),
"description" (detailed action),
"tool" (one of: 'search_files', 'browser_read', 'write_file', 'run_tests', 'create_pull_request').
Output ONLY valid JSON array.''',
              },
              {'role': 'user', 'content': 'Task: $taskPrompt\nRepository: $repoPath'},
            ],
            'temperature': 0.2,
          }),
        ).timeout(const Duration(seconds: 20));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          var text = data['choices'][0]['message']['content'] as String;
          text = text.replaceAll('```json', '').replaceAll('```', '').trim();
          final list = jsonDecode(text) as List;

          final uuid = const Uuid();
          return list.map((item) {
            final m = item as Map<String, dynamic>;
            return PlanItem(
              id: uuid.v4(),
              title: m['title']?.toString() ?? 'Milestone',
              description: m['description']?.toString() ?? '',
              status: PlanItemStatus.pending,
              tool: m['tool']?.toString(),
            );
          }).toList();
        }
      } catch (_) {
        // Fall back to rule-based planner
      }
    }

    return _generateRuleBasedPlan(taskPrompt);
  }

  List<PlanItem> _generateRuleBasedPlan(String taskPrompt) {
    final uuid = const Uuid();
    return [
      PlanItem(
        id: uuid.v4(),
        title: 'Explore Repository & Locate Issue Context',
        description: 'Scan repository directory structure, grep relevant source files, and inspect failing stack traces.',
        status: PlanItemStatus.pending,
        tool: 'search_files',
      ),
      PlanItem(
        id: uuid.v4(),
        title: 'Browse Documentation & Library Specifications',
        description: 'Access official library docs or specs via in-agent browser to determine correct API patterns.',
        status: PlanItemStatus.pending,
        tool: 'browser_read',
      ),
      PlanItem(
        id: uuid.v4(),
        title: 'Implement Code Changes & Bug Fixes',
        description: 'Edit target source files to resolve the issue with clean, defensive implementation.',
        status: PlanItemStatus.pending,
        tool: 'write_file',
      ),
      PlanItem(
        id: uuid.v4(),
        title: 'Execute Test Suite & Iterate on Failures',
        description: 'Run automated unit and integration tests. Catch regressions and iterate until all tests pass.',
        status: PlanItemStatus.pending,
        tool: 'run_tests',
      ),
      PlanItem(
        id: uuid.v4(),
        title: 'Create Branch, Commit & Open Pull Request',
        description: 'Stage modified files, commit with descriptive message, push branch, and open PR with detailed changelog.',
        status: PlanItemStatus.pending,
        tool: 'create_pull_request',
      ),
    ];
  }
}
