import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PageText {
  final int pageNumber;
  final String text;

  PageText({required this.pageNumber, required this.text});
}

class PdfExtractor {
  static Future<List<PageText>> extractPages(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $filePath');
    }

    final ext = p.extension(filePath).toLowerCase();

    if (ext == '.txt' || ext == '.md') {
      final text = await file.readAsString();
      return [PageText(pageNumber: 1, text: text)];
    }

    if (ext == '.pdf') {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      try {
        final extractor = PdfTextExtractor(document);
        final results = <PageText>[];

        for (int i = 0; i < document.pages.count; i++) {
          final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
          results.add(PageText(
            pageNumber: i + 1,
            text: pageText.trim(),
          ));
        }

        return results;
      } finally {
        document.dispose();
      }
    }

    // Default fallback to raw text reading
    try {
      final text = await file.readAsString();
      return [PageText(pageNumber: 1, text: text)];
    } catch (_) {
      return [];
    }
  }
}
