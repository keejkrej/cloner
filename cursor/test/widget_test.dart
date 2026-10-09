import 'package:flutter_test/flutter_test.dart';
import 'package:cursor_clone/core/diff/diff_engine.dart';
import 'package:cursor_clone/features/editor/editor_state.dart';

void main() {
  test('DiffEngine detects code replacements', () {
    const original = 'line one\nold line\nline three';
    const updated = 'line one\nnew line\nline three';

    final diff = DiffEngine.computeDiff(original, updated);
    expect(diff.any((d) => d.type == '-' && d.text.contains('old')), true);
    expect(diff.any((d) => d.type == '+' && d.text.contains('new')), true);
  });

  test('EditorState propose, accept, and reject lifecycle', () {
    final state = EditorState();
    state.updateContent('const x = 10;');

    state.proposeEdit('const x = 20;');
    expect(state.hasPendingDiff, true);
    expect(state.pendingDiffLines!.isNotEmpty, true);

    // Reject reverts
    state.rejectDiff();
    expect(state.hasPendingDiff, false);
    expect(state.fileContent, 'const x = 10;');

    // Propose and accept
    state.proposeEdit('const x = 30;');
    state.acceptDiff();
    expect(state.hasPendingDiff, false);
    expect(state.fileContent, 'const x = 30;');
  });
}
