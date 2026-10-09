class TextChunker {
  /// Splits text into natural chunks suitable for TTS synthesis.
  /// Target max chunk size is around [maxChunkLength] characters.
  static List<String> chunkText(String text, {int maxChunkLength = 1200}) {
    final clean = text.trim();
    if (clean.isEmpty) return [];
    if (clean.length <= maxChunkLength) return [clean];

    final chunks = <String>[];
    final paragraphs = clean.split(RegExp(r'\n+'));

    var currentChunk = StringBuffer();

    for (final paragraph in paragraphs) {
      final trimmedPara = paragraph.trim();
      if (trimmedPara.isEmpty) continue;

      if (trimmedPara.length > maxChunkLength) {
        // If a single paragraph is too large, split by sentences
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.toString().trim());
          currentChunk = StringBuffer();
        }

        final sentences = _splitIntoSentences(trimmedPara);
        for (final sentence in sentences) {
          if (currentChunk.length + sentence.length + 1 > maxChunkLength) {
            if (currentChunk.isNotEmpty) {
              chunks.add(currentChunk.toString().trim());
              currentChunk = StringBuffer();
            }

            if (sentence.length > maxChunkLength) {
              // Extremely long sentence without punctuation, split by words
              final words = sentence.split(RegExp(r'\s+'));
              for (final word in words) {
                if (currentChunk.length + word.length + 1 > maxChunkLength) {
                  if (currentChunk.isNotEmpty) {
                    chunks.add(currentChunk.toString().trim());
                    currentChunk = StringBuffer();
                  }
                }
                if (currentChunk.isNotEmpty) currentChunk.write(' ');
                currentChunk.write(word);
              }
            } else {
              currentChunk.write(sentence);
            }
          } else {
            if (currentChunk.isNotEmpty) currentChunk.write(' ');
            currentChunk.write(sentence);
          }
        }
      } else {
        // Paragraph fits
        if (currentChunk.length + trimmedPara.length + 2 > maxChunkLength) {
          if (currentChunk.isNotEmpty) {
            chunks.add(currentChunk.toString().trim());
            currentChunk = StringBuffer();
          }
        }
        if (currentChunk.isNotEmpty) currentChunk.write('\n\n');
        currentChunk.write(trimmedPara);
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.toString().trim());
    }

    return chunks;
  }

  static List<String> _splitIntoSentences(String text) {
    final sentenceEndings = RegExp(r'(?<=[.!?])\s+');
    final raw = text.split(sentenceEndings);
    return raw.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
}
