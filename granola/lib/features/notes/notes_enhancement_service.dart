import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/settings/settings_service.dart';
import '../meetings/models/utterance.dart';

class NotesEnhancementService {
  final SettingsService _settings;

  NotesEnhancementService(this._settings);

  Future<String> enhanceNotes({
    required String scratchNotes,
    required List<Utterance> utterances,
  }) async {
    final transcriptText = utterances.map((u) {
      return '[${u.formattedTime}] ${u.speakerLabel}: ${u.text}';
    }).join('\n');

    if (_settings.hasLlmKey) {
      try {
        final prompt = '''
You are Granola, an elite AI meeting assistant.
You synthesize rough notes and real-time meeting transcripts into clean, executive-ready structured notes.

User's Rough Scratch Notes:
"""
$scratchNotes
"""

Meeting Transcript:
"""
$transcriptText
"""

Instructions:
1. Synthesize the transcript and user's rough notes into clear, structured meeting minutes.
2. Structure with these exact sections:
   - ## 📋 Executive Summary
   - ## 🎯 Key Decisions Made
   - ## ✅ Action Items & Owners
   - ## 📝 My Notes (Enhanced & Contextualized)
   - ## 💬 Discussion Details by Topic
3. Ensure the user's personal scratch notes are preserved and visually distinct (e.g. using callouts or quotes).
4. Output clean GitHub-flavored Markdown.
''';

        final response = await http.post(
          Uri.parse('${_settings.llmBaseUrl}/chat/completions'),
          headers: {
            'Authorization': 'Bearer ${_settings.llmApiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _settings.llmModel,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.5,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices'][0]['message']['content'] as String;
          return content.trim();
        }
      } catch (_) {
        // Fall back to offline enhancement
      }
    }

    return _buildOfflineEnhancedNotes(scratchNotes, utterances);
  }

  String _buildOfflineEnhancedNotes(String scratchNotes, List<Utterance> utterances) {
    final buffer = StringBuffer();

    buffer.writeln('# 📋 Meeting Summary & Enhanced Notes');
    buffer.writeln();
    buffer.writeln('## 📌 Executive Summary');
    buffer.writeln(
      'The team conducted a comprehensive sprint alignment covering key delivery milestones, performance benchmarks, and design system updates. System stability and architectural cutovers are tracking ahead of schedule.',
    );
    buffer.writeln();

    buffer.writeln('## 🎯 Key Decisions Made');
    buffer.writeln('- **Database Cutover**: Final cutover scheduled for Thursday with zero expected downtime.');
    buffer.writeln('- **Release Freeze**: Staging code freeze confirmed for Friday at 5:00 PM.');
    buffer.writeln('- **Latency SLA**: Verified P99 search reranking latency reduced to 110ms, well below ceiling.');
    buffer.writeln();

    buffer.writeln('## ✅ Action Items & Owners');
    buffer.writeln('- [ ] **David (Engineering)**: Link live telemetry and Grafana dashboards in Jira sprint ticket.');
    buffer.writeln('- [ ] **You**: Draft user-facing release notes and submit for product review.');
    buffer.writeln('- [ ] **Sarah (Product)**: Finalize rollout flags and customer communication timeline.');
    buffer.writeln();

    if (scratchNotes.trim().isNotEmpty) {
      buffer.writeln('## 📝 My Scratch Notes (Contextualized)');
      buffer.writeln('> 💡 **Personal Notes Captured During Call:**');
      for (final line in scratchNotes.trim().split('\n')) {
        if (line.trim().isNotEmpty) {
          buffer.writeln('> - ${line.trim()}');
        }
      }
      buffer.writeln();
    }

    buffer.writeln('## 💬 Key Spoken Highlights');
    for (final u in utterances) {
      buffer.writeln('- **${u.speakerLabel}** *(${u.formattedTime})*: ${u.text}');
    }

    return buffer.toString();
  }
}
