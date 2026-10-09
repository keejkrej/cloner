import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../core/diff/diff_service.dart';
import '../../core/jail/jail_service.dart';

typedef ApprovalCallback = Future<bool> Function({
  required String toolName,
  required String target,
  required String details,
  List<DiffLine>? diffLines,
});

class ToolResult {
  final bool success;
  final String output;
  final List<DiffLine>? diffLines;

  ToolResult({required this.success, required this.output, this.diffLines});
}

class ToolExecutor {
  final String workingDir;
  final ApprovalCallback requestApproval;
  final bool autoApprove;
  final void Function(String line)? onCommandOutput;

  ToolExecutor({
    required this.workingDir,
    required this.requestApproval,
    this.autoApprove = false,
    this.onCommandOutput,
  });

  Future<ToolResult> execute(String name, Map<String, dynamic> args) async {
    try {
      switch (name) {
        case 'list_dir':
          return await _listDir(args['path'] as String? ?? '.');

        case 'read_file':
          return await _readFile(
            args['path'] as String,
            offsetLine: args['offset_line'] as int?,
            limitLines: args['limit_lines'] as int?,
          );

        case 'grep':
          return await _grep(
            args['pattern'] as String,
            subPath: args['path'] as String?,
          );

        case 'write_file':
          return await _writeFile(
            args['path'] as String,
            args['content'] as String,
          );

        case 'edit_file':
          return await _editFile(
            args['path'] as String,
            args['target_string'] as String,
            args['replacement_string'] as String,
          );

        case 'run_command':
          return await _runCommand(args['command'] as String);

        default:
          return ToolResult(success: false, output: 'Unknown tool: $name');
      }
    } on JailSecurityException catch (e) {
      return ToolResult(success: false, output: e.toString());
    } catch (e) {
      return ToolResult(success: false, output: 'Error executing $name: $e');
    }
  }

  Future<ToolResult> _listDir(String relativePath) async {
    final fullPath = JailService.resolveAndValidate(relativePath, workingDir);
    final dir = Directory(fullPath);

    if (!await dir.exists()) {
      return ToolResult(success: false, output: 'Directory does not exist: $relativePath');
    }

    final entries = await dir.list().toList();
    final buffer = StringBuffer();
    buffer.writeln('Directory contents for "$relativePath":');

    for (final e in entries) {
      final name = p.basename(e.path);
      if (name.startsWith('.') || name == 'node_modules' || name == 'build') continue;
      final isDir = e is Directory;
      buffer.writeln('${isDir ? "[DIR] " : "      "}$name');
    }

    return ToolResult(success: true, output: buffer.toString().trim());
  }

  Future<ToolResult> _readFile(String relativePath, {int? offsetLine, int? limitLines}) async {
    final fullPath = JailService.resolveAndValidate(relativePath, workingDir);
    final file = File(fullPath);

    if (!await file.exists()) {
      return ToolResult(success: false, output: 'File not found: $relativePath');
    }

    final lines = await file.readAsLines();
    final start = (offsetLine != null && offsetLine > 0) ? offsetLine - 1 : 0;
    final count = (limitLines != null && limitLines > 0) ? limitLines : lines.length;
    final end = (start + count).clamp(0, lines.length);

    final buffer = StringBuffer();
    for (int i = start; i < end; i++) {
      buffer.writeln('${(i + 1).toString().padLeft(4)}: ${lines[i]}');
    }

    return ToolResult(success: true, output: buffer.toString());
  }

  Future<ToolResult> _grep(String pattern, {String? subPath}) async {
    final targetPath = JailService.resolveAndValidate(subPath ?? '.', workingDir);
    final rootDir = Directory(targetPath);

    if (!await rootDir.exists()) {
      return ToolResult(success: false, output: 'Path does not exist: $subPath');
    }

    final regExp = RegExp(pattern, caseSensitive: false);
    final buffer = StringBuffer();
    int matchCount = 0;

    await for (final entity in rootDir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final rel = p.relative(entity.path, from: workingDir);
        if (rel.startsWith('.') || rel.contains('build') || rel.contains('.dart_tool')) continue;

        try {
          final lines = await entity.readAsLines();
          for (int i = 0; i < lines.length; i++) {
            if (regExp.hasMatch(lines[i])) {
              buffer.writeln('$rel:${i + 1}: ${lines[i].trim()}');
              matchCount++;
              if (matchCount >= 50) break;
            }
          }
        } catch (_) {}
      }
      if (matchCount >= 50) break;
    }

    if (matchCount == 0) {
      return ToolResult(success: true, output: 'No matches found for "$pattern".');
    }

    return ToolResult(success: true, output: buffer.toString().trim());
  }

  Future<ToolResult> _writeFile(String relativePath, String content) async {
    final fullPath = JailService.resolveAndValidate(relativePath, workingDir);

    if (!autoApprove) {
      final approved = await requestApproval(
        toolName: 'write_file',
        target: relativePath,
        details: 'Write ${content.length} characters to $relativePath',
      );
      if (!approved) {
        return ToolResult(success: false, output: 'Operation refused by user.');
      }
    }

    final file = File(fullPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);

    return ToolResult(success: true, output: 'Successfully wrote to $relativePath (${content.length} bytes).');
  }

  Future<ToolResult> _editFile(String relativePath, String targetString, String replacementString) async {
    final fullPath = JailService.resolveAndValidate(relativePath, workingDir);
    final file = File(fullPath);

    if (!await file.exists()) {
      return ToolResult(success: false, output: 'File does not exist: $relativePath');
    }

    final original = await file.readAsString();
    if (!original.contains(targetString)) {
      return ToolResult(
        success: false,
        output: 'target_string not found in $relativePath. Make sure target matches exact characters.',
      );
    }

    final occurrences = targetString.allMatches(original).length;
    if (occurrences > 1) {
      return ToolResult(
        success: false,
        output: 'target_string matched multiple times ($occurrences) in $relativePath. Provide more surrounding context.',
      );
    }

    final updated = original.replaceFirst(targetString, replacementString);
    final diffLines = DiffService.generateDiff(original, updated);

    if (!autoApprove) {
      final approved = await requestApproval(
        toolName: 'edit_file',
        target: relativePath,
        details: 'Replace exact block in $relativePath',
        diffLines: diffLines,
      );
      if (!approved) {
        return ToolResult(success: false, output: 'Edit refused by user.');
      }
    }

    await file.writeAsString(updated);
    return ToolResult(
      success: true,
      output: 'Successfully applied edit to $relativePath.',
      diffLines: diffLines,
    );
  }

  Future<ToolResult> _runCommand(String command) async {
    if (!autoApprove) {
      final approved = await requestApproval(
        toolName: 'run_command',
        target: workingDir,
        details: command,
      );
      if (!approved) {
        return ToolResult(success: false, output: 'Command execution refused by user.');
      }
    }

    try {
      final isWindows = Platform.isWindows;
      final executable = isWindows ? 'powershell.exe' : '/bin/sh';
      final arguments = isWindows ? ['-NoProfile', '-Command', command] : ['-c', command];

      final process = await Process.start(
        executable,
        arguments,
        workingDirectory: workingDir,
      );

      final outputBuffer = StringBuffer();
      final completer = Completer<int>();

      process.stdout.transform(utf8.decoder).listen((data) {
        outputBuffer.write(data);
        onCommandOutput?.call(data);
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        outputBuffer.write(data);
        onCommandOutput?.call(data);
      });

      process.exitCode.then((code) {
        if (!completer.isCompleted) completer.complete(code);
      });

      // 30 seconds timeout
      final exitCode = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );

      var out = outputBuffer.toString();
      // Output truncation if too large
      if (out.length > 30000) {
        out = '${out.substring(0, 30000)}\n\n[...output truncated after 30KB...]';
      }

      return ToolResult(
        success: exitCode == 0,
        output: 'Exit code: $exitCode\n$out',
      );
    } catch (e) {
      return ToolResult(success: false, output: 'Process execution error: $e');
    }
  }
}
