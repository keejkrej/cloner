import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:claudecode/core/diff/diff_service.dart';
import 'package:claudecode/core/jail/jail_service.dart';
import 'package:claudecode/features/tools/tool_definition.dart';

void main() {
  test('JailService refuses paths outside project working directory', () {
    final tempDir = Directory.systemTemp.createTempSync('jail_test');
    try {
      final safeInside = JailService.resolveAndValidate('subfolder/file.dart', tempDir.path);
      expect(safeInside.startsWith(tempDir.path) || safeInside.toLowerCase().startsWith(tempDir.path.toLowerCase()), true);

      // Traversal outside jail must throw
      expect(
        () => JailService.resolveAndValidate('../../secret.txt', tempDir.path),
        throwsA(isA<JailSecurityException>()),
      );
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('DiffService generates unified diff lines accurately', () {
    const oldCode = 'void main() {\n  print("hello");\n}';
    const newCode = 'void main() {\n  print("world");\n}';

    final diffs = DiffService.generateDiff(oldCode, newCode);
    expect(diffs.any((d) => d.type == '-' && d.text.contains('hello')), true);
    expect(diffs.any((d) => d.type == '+' && d.text.contains('world')), true);
  });

  test('ToolDefinition contains all 6 core tools', () {
    final tools = ToolDefinition.allTools;
    final names = tools.map((t) => t['function']['name'] as String).toList();
    expect(names, containsAll(['list_dir', 'read_file', 'grep', 'write_file', 'edit_file', 'run_command']));
  });
}
