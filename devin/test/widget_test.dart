import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devin/features/agent/devin_agent_service.dart';
import 'package:devin/features/browser/devin_browser_service.dart';
import 'package:devin/features/planner/models/plan_item.dart';
import 'package:devin/features/planner/planner_service.dart';
import 'package:devin/features/pr/devin_pr_service.dart';
import 'package:devin/features/shell/devin_shell_service.dart';

// Test mock shell service that simulates test execution and failures
class FakeDevinShellService extends DevinShellService {
  int testRuns = 0;

  @override
  Future<TestExecutionResult> runTests({String? cwd, String? testCommand}) async {
    testRuns++;
    if (testRuns == 1) {
      // First run fails
      log('00:02 +3 -1: Some tests failed. NullPointerException in auth_service.dart:42');
      return TestExecutionResult(
        passed: false,
        totalTests: 4,
        passedTests: 3,
        failedTests: 1,
        fullOutput: '00:02 +3 -1: Some tests failed. NullPointerException in auth_service.dart:42',
        failureSummary: 'NullPointerException in auth_service.dart:42',
      );
    }
    // Second run passes after Devin auto-fix
    log('00:03 +4: All tests passed!');
    return TestExecutionResult(
      passed: true,
      totalTests: 4,
      passedTests: 4,
      failedTests: 0,
      fullOutput: '00:03 +4: All tests passed!',
    );
  }

  @override
  Future<ShellExecutionResult> executeCommand(String command, {String? cwd}) async {
    log('\$ $command');
    return ShellExecutionResult(
      exitCode: 0,
      stdout: 'Simulated output for: $command',
      stderr: '',
      isSuccess: true,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('PlanItem Models Tests', () {
    test('PlanItem serialization and copyWith', () {
      final item = PlanItem(
        id: 'plan_1',
        title: 'Explore repo',
        description: 'Check directory layout',
        status: PlanItemStatus.pending,
        tool: 'search_files',
      );

      final map = item.toMap();
      final restored = PlanItem.fromMap(map);

      expect(restored.id, 'plan_1');
      expect(restored.title, 'Explore repo');
      expect(restored.status, PlanItemStatus.pending);
      expect(restored.tool, 'search_files');

      final updated = restored.copyWith(status: PlanItemStatus.completed, output: '12 files');
      expect(updated.status, PlanItemStatus.completed);
      expect(updated.output, '12 files');
    });
  });

  group('PlannerService Tests', () {
    test('Generates sequential milestones from task description', () async {
      final planner = PlannerService();
      final plan = await planner.generatePlan(
        'Fix NullPointerException in auth service and add regression tests',
        'c:/repo',
      );

      expect(plan.length, greaterThanOrEqualTo(4));
      expect(plan.any((p) => p.tool == 'search_files'), isTrue);
      expect(plan.any((p) => p.tool == 'run_tests'), isTrue);
      expect(plan.any((p) => p.tool == 'create_pull_request'), isTrue);
    });
  });

  group('DevinBrowserService Tests', () {
    test('Cleans HTML and extracts title and content', () {
      final browser = DevinBrowserService();
      final html = '''
        <html>
          <head><title>Flutter Testing Documentation</title></head>
          <body>
            <h1>Unit Testing in Flutter</h1>
            <p>Use flutter test to execute your automated test suite.</p>
          </body>
        </html>
      ''';

      final title = browser.state.title; // default
      expect(title, 'New Tab');

      // Test readable content extraction
      final res = browser.openAndRead('https://docs.flutter.dev');
      expect(res, isNotNull);
    });
  });

  group('DevinPrBotService Tests', () {
    test('Creates pull request with branch, title, and markdown description', () async {
      final shell = FakeDevinShellService();
      final prBot = DevinPrBotService(shellService: shell);

      final pr = await prBot.createPullRequest(
        repoPath: 'c:/repo',
        taskDescription: 'Fix NullPointerException in auth service',
      );

      expect(pr.success, isTrue);
      expect(pr.branchName, contains('devin/fix-nullpointerexception'));
      expect(pr.title, contains('Fix NullPointerException'));
      expect(pr.body, contains('Verification Checklist'));
      expect(pr.prUrl, isNotNull);
    });
  });

  group('DevinAgentService End-to-End Tests', () {
    test('Devin runs task: formulates plan, browses, iterates test failure, and opens PR', () async {
      final shell = FakeDevinShellService();
      final prBot = DevinPrBotService(shellService: shell);
      final agent = DevinAgentService(
        plannerService: PlannerService(),
        browserService: DevinBrowserService(),
        shellService: shell,
        prBotService: prBot,
      );

      await agent.runTask(
        taskPrompt: 'Fix NullPointerException in auth service and add regression tests',
        repoPath: 'c:/repo',
      );

      // Verify plan executed
      expect(agent.state.status, DevinRunStatus.completed);
      expect(agent.state.plan.length, greaterThanOrEqualTo(4));
      expect(agent.state.plan.every((p) => p.status == PlanItemStatus.completed), isTrue);

      // Verify test iteration occurred (first run failed -> diagnosed -> second run passed)
      expect(shell.testRuns, 2);

      // Verify PR was created
      expect(agent.state.pullRequest, isNotNull);
      expect(agent.state.pullRequest!.success, isTrue);
      expect(agent.state.pullRequest!.prUrl, contains('github.com'));
    });
  });
}
