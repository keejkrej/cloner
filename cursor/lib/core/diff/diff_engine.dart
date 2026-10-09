import 'package:diff_match_patch/diff_match_patch.dart';

class DiffLineItem {
  final String type; // '+', '-', ' '
  final String text;

  DiffLineItem({required this.type, required this.text});
}

class DiffEngine {
  static List<DiffLineItem> computeDiff(String oldText, String newText) {
    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(oldText, newText);
    dmp.diffCleanupSemantic(diffs);

    final result = <DiffLineItem>[];
    for (final diff in diffs) {
      final lines = diff.text.split('\n');
      for (int i = 0; i < lines.length; i++) {
        if (i == lines.length - 1 && lines[i].isEmpty) continue;
        final line = lines[i];
        if (diff.operation == DIFF_INSERT) {
          result.add(DiffLineItem(type: '+', text: line));
        } else if (diff.operation == DIFF_DELETE) {
          result.add(DiffLineItem(type: '-', text: line));
        } else {
          result.add(DiffLineItem(type: ' ', text: line));
        }
      }
    }
    return result;
  }
}
