import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ShellExecutionResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  final bool isSuccess;

  ShellExecutionResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.isSuccess,
  });
}

class TestExecutionResult {
  final bool passed;
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final String fullOutput;
  final String? failureSummary;

  TestExecutionResult({
    required this.passed,
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.fullOutput,
    this.failureSummary,
  });
}

class DevinShellService {
  final _outputController = StreamController<String>.broadcast();
  Stream<String> get onOutput => _outputController.stream;

  final List<String> _history = [];
  List<String> get history => _history;

  void log(String message) {
    _history.add(message);
    _outputController.add(message);
  }

  Future<ShellExecutionResult> executeCommand(String command, {String? cwd}) async {
    log('\$ $command');

    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      // In headless test mock
      final msg = 'Executed: $command (simulated)';
      log(msg);
      return ShellExecutionResult(exitCode: 0, stdout: msg, stderr: '', isSuccess: true);
    }

    try {
      final shell = Platform.isWindows ? 'powershell' : 'bash';
      final flag = Platform.isWindows ? '-Command' : '-c';

      final process = await Process.start(
        shell,
        [flag, command],
        workingDirectory: cwd,
      );

      final stdoutBuf = StringBuffer();
      final stderrBuf = StringBuffer();

      final outSub = process.stdout.transform(utf8.decoder).listen((data) {
        stdoutBuf.write(data);
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) log(line.trimRight());
        }
      });

      final errSub = process.stderr.transform(utf8.decoder).listen((data) {
        stderrBuf.write(data);
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) log('[ERR] ${line.trimRight()}');
        }
      });

      final exitCode = await process.exitCode.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          process.kill();
          return -1;
        },
      );

      await outSub.cancel();
      await errSub.cancel();

      return ShellExecutionResult(
        exitCode: exitCode,
        stdout: stdoutBuf.toString(),
        stderr: stderrBuf.toString(),
        isSuccess: exitCode == 0,
      );
    } catch (e) {
      log('Shell execution failed: $e');
      return ShellExecutionResult(
        exitCode: 1,
        stdout: '',
        stderr: e.toString(),
        isSuccess: false,
      );
    }
  }

  Future<TestExecutionResult> runTests({String? cwd, String? testCommand}) async {
    log('Running test suite in $cwd...');

    String cmd = testCommand ?? '';
    if (cmd.isEmpty) {
      // Detect test command
      if (cwd != null) {
        if (File('$cwd/pubspec.yaml').existsSync()) {
          cmd = 'flutter test';
        } else if (File('$cwd/package.json').existsSync()) {
          cmd = 'npm test';
        } else if (File('$cwd/pytest.ini').existsSync() || File('$cwd/tests').existsSync()) {
          cmd = 'pytest';
        } else {
          cmd = 'dart test';
        }
      } else {
        cmd = 'dart test';
      }
    }

    final execResult = await executeCommand(cmd, cwd: cwd);
    final output = '${execResult.stdout}\n${execResult.stderr}';

    // Parse test results
    bool passed = execResult.isSuccess;
    int total = 1;
    int passedCount = passed ? 1 : 0;
    int failedCount = passed ? 0 : 1;
    String? failureSummary;

    // Check Dart/Flutter test pattern: "00:05 +14: All tests passed!" or "00:03 +5 -2: Some tests failed."
    final dartPassMatch = RegExp(r'\+(\d+)(?:\s*-\s*(\d+))?:\s*(All tests passed|Some tests failed)').firstMatch(output);
    if (dartPassMatch != null) {
      passedCount = int.tryParse(dartPassMatch.group(1) ?? '0') ?? 0;
      failedCount = int.tryParse(dartPassMatch.group(2) ?? '0') ?? 0;
      total = passedCount + failedCount;
      passed = failedCount == 0 && passedCount > 0;
    }

    if (!passed) {
      failureSummary = 'Tests failed: $failedCount failing, $passedCount passing.';
    }

    return TestExecutionResult(
      passed: passed,
      totalTests: total,
      passedTests: passedCount,
      failedTests: failedCount,
      fullOutput: output,
      failureSummary: failureSummary,
    );
  }

  void clear() {
    _history.clear();
  }

  void dispose() {
    _outputController.close();
  }
}
