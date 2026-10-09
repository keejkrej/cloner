import 'package:flutter_test/flutter_test.dart';
import 'package:notebooklm/core/ingest/pdf_extractor.dart';
import 'package:notebooklm/core/rag/rag_service.dart';
import 'package:notebooklm/features/notebook/models.dart';

void main() {
  test('NotebookLM model serialization', () {
    final now = DateTime.now();
    final nb = Notebook(
      id: 'nb-1',
      title: 'Quantum Physics Papers',
      createdAt: now,
      updatedAt: now,
    );

    final map = nb.toMap();
    final restored = Notebook.fromMap(map);
    expect(restored.id, 'nb-1');
    expect(restored.title, 'Quantum Physics Papers');

    final line = DialogueLine(speaker: 'Alex', text: 'Welcome to the podcast!');
    final lineMap = line.toMap();
    final restoredLine = DialogueLine.fromMap(lineMap);
    expect(restoredLine.speaker, 'Alex');
    expect(restoredLine.text, 'Welcome to the podcast!');
  });

  test('PageText and chunking structure', () {
    final page = PageText(
      pageNumber: 2,
      text: 'Quantum error correction is a set of techniques to protect information.',
    );
    expect(page.pageNumber, 2);
    expect(page.text.contains('Quantum error correction'), true);
  });
}
