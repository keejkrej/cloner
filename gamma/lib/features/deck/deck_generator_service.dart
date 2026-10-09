import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../core/settings/settings_service.dart';
import 'models/deck.dart';
import 'models/slide.dart';

class OutlineItem {
  String layout;
  String title;
  String summary;

  OutlineItem({
    required this.layout,
    required this.title,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
        'layout': layout,
        'title': title,
        'summary': summary,
      };

  factory OutlineItem.fromJson(Map<String, dynamic> json) => OutlineItem(
        layout: json['layout'] ?? 'bullets',
        title: json['title'] ?? 'Slide Title',
        summary: json['summary'] ?? '',
      );
}

class DeckGeneratorService {
  final SettingsService _settings;
  final _uuid = const Uuid();

  DeckGeneratorService(this._settings);

  /// Generates a structured outline of 5-7 slides based on the user's topic
  Future<List<OutlineItem>> generateOutline(String topic) async {
    if (_settings.hasKey) {
      try {
        final prompt = '''
You are Gamma's slide deck architect.
For the topic: "$topic", generate a structured slide deck outline of 6 slides.
You MUST pick varied layouts from: 'title', 'bullets', 'two_column', 'image_text', 'big_number', 'quote'.
Ensure the first slide is 'title', and the others use different layouts for visual variety.

Return ONLY a valid JSON array of objects with keys:
- "layout": one of ('title', 'bullets', 'two_column', 'image_text', 'big_number', 'quote')
- "title": concise slide title
- "summary": 1-sentence description of the slide focus

Example:
[
  {"layout": "title", "title": "The Quantum Shift", "summary": "Introduction to next-gen quantum computing"},
  {"layout": "bullets", "title": "Core Architectural Pillars", "summary": "Three fundamental breakthroughs in qubit stability"},
  {"layout": "big_number", "title": "Exponential Speedup", "summary": "Key performance milestone and benchmarks"},
  {"layout": "two_column", "title": "Classical vs Quantum", "summary": "Direct comparative analysis across speed and power"},
  {"layout": "image_text", "title": "Hardware Cryogenics", "summary": "Visual overview of dilution refrigerator infrastructure"},
  {"layout": "quote", "title": "The Industry Vision", "summary": "Inspiring closing perspective from leading researcher"}
]
''';

        final response = await http.post(
          Uri.parse('${_settings.baseUrl}/chat/completions'),
          headers: {
            'Authorization': 'Bearer ${_settings.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _settings.model,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.7,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final rawContent = data['choices'][0]['message']['content'] as String;
          final jsonString = _extractJson(rawContent);
          final decoded = jsonDecode(jsonString);
          if (decoded is List) {
            return decoded.map((e) => OutlineItem.fromJson(e as Map<String, dynamic>)).toList();
          }
        }
      } catch (_) {
        // Fall back to offline outline
      }
    }

    // Default template-based outline
    return _buildFallbackOutline(topic);
  }

  /// Converts the edited outline into a full, richly styled deck of slides
  Future<Deck> generateFullDeck({
    required String topic,
    required List<OutlineItem> outline,
    required String themeId,
  }) async {
    final deckId = _uuid.v4();

    if (_settings.hasKey) {
      try {
        final outlineJson = jsonEncode(outline.map((e) => e.toJson()).toList());
        final prompt = '''
You are an elite presentation designer at Gamma.
Generate a complete, fully populated slide deck for the topic: "$topic".
Follow this structured outline exactly:
$outlineJson

For each outline item, generate the complete slide content with rich details.
Return ONLY a valid JSON array of slide objects with this schema:
[
  {
    "layout": "title" | "bullets" | "two_column" | "image_text" | "big_number" | "quote",
    "title": "String",
    "subtitle": "String or null",
    "bullets": ["Point 1", "Point 2", "Point 3"] (for bullets layout),
    "left_column_title": "String" (for two_column),
    "left_column_text": "String" (for two_column),
    "right_column_title": "String" (for two_column),
    "right_column_text": "String" (for two_column),
    "stat_number": "e.g. 10x or 99.8%" (for big_number),
    "stat_label": "String explaining the stat" (for big_number),
    "quote_text": "String" (for quote),
    "quote_author": "String" (for quote),
    "image_prompt": "Keyword for visual search" (for image_text or title)
  }
]
''';

        final response = await http.post(
          Uri.parse('${_settings.baseUrl}/chat/completions'),
          headers: {
            'Authorization': 'Bearer ${_settings.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _settings.model,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.7,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final rawContent = data['choices'][0]['message']['content'] as String;
          final jsonString = _extractJson(rawContent);
          final decoded = jsonDecode(jsonString);
          if (decoded is List) {
            final slides = <Slide>[];
            for (int i = 0; i < decoded.length; i++) {
              final sMap = decoded[i] as Map<String, dynamic>;
              final imgPrompt = sMap['image_prompt'] ?? topic;
              slides.add(
                Slide(
                  id: _uuid.v4(),
                  deckId: deckId,
                  slideOrder: i,
                  layout: sMap['layout'] ?? outline[i].layout,
                  title: sMap['title'] ?? outline[i].title,
                  subtitle: sMap['subtitle'],
                  bullets: (sMap['bullets'] as List?)?.map((e) => e.toString()).toList() ?? [],
                  leftColumnTitle: sMap['left_column_title'],
                  leftColumnText: sMap['left_column_text'],
                  rightColumnTitle: sMap['right_column_title'],
                  rightColumnText: sMap['right_column_text'],
                  statNumber: sMap['stat_number'],
                  statLabel: sMap['stat_label'],
                  quoteText: sMap['quote_text'],
                  quoteAuthor: sMap['quote_author'],
                  imageUrl: _getThematicImageUrl(imgPrompt),
                  imagePrompt: imgPrompt,
                ),
              );
            }

            return Deck(
              id: deckId,
              title: outline.isNotEmpty ? outline.first.title : topic,
              topic: topic,
              themeId: themeId,
              slides: slides,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            );
          }
        }
      } catch (_) {
        // Fall back to offline generator
      }
    }

    return _buildFallbackDeck(deckId, topic, outline, themeId);
  }

  List<OutlineItem> _buildFallbackOutline(String topic) {
    return [
      OutlineItem(
        layout: 'title',
        title: topic,
        summary: 'Overview and strategic vision for $topic',
      ),
      OutlineItem(
        layout: 'bullets',
        title: 'Key Strategic Drivers',
        summary: 'Core challenges, market signals, and primary goals',
      ),
      OutlineItem(
        layout: 'big_number',
        title: 'Measurable Impact',
        summary: 'Critical KPI and exponential performance leap',
      ),
      OutlineItem(
        layout: 'two_column',
        title: 'Traditional vs Modern Approach',
        summary: 'Comparative breakdown of legacy limitations and modern solutions',
      ),
      OutlineItem(
        layout: 'image_text',
        title: 'Ecosystem & Execution',
        summary: 'Operational architecture and practical deployment',
      ),
      OutlineItem(
        layout: 'quote',
        title: 'Guiding Philosophy',
        summary: 'Inspiring insight into the transformative road ahead',
      ),
    ];
  }

  Deck _buildFallbackDeck(
    String deckId,
    String topic,
    List<OutlineItem> outline,
    String themeId,
  ) {
    final slides = <Slide>[];

    for (int i = 0; i < outline.length; i++) {
      final item = outline[i];
      final order = i;

      switch (item.layout) {
        case 'title':
          slides.add(Slide(
            id: _uuid.v4(),
            deckId: deckId,
            slideOrder: order,
            layout: 'title',
            title: item.title,
            subtitle: 'A Comprehensive Deep-Dive and Strategic Playbook',
            imageUrl: _getThematicImageUrl(topic),
            imagePrompt: topic,
          ));
          break;

        case 'bullets':
          slides.add(Slide(
            id: _uuid.v4(),
            deckId: deckId,
            slideOrder: order,
            layout: 'bullets',
            title: item.title,
            subtitle: 'Core pillars driving transformation and sustainable adoption',
            bullets: [
              'Accelerated time-to-value through streamlined autonomous orchestration.',
              'Frictionless integration across existing enterprise data pipelines and workflows.',
              'Continuous feedback loops ensuring high accuracy, safety, and operational resilience.',
            ],
          ));
          break;

        case 'big_number':
          slides.add(Slide(
            id: _uuid.v4(),
            deckId: deckId,
            slideOrder: order,
            layout: 'big_number',
            title: item.title,
            statNumber: '10x',
            statLabel: 'Increase in operational efficiency and execution velocity compared to baseline benchmarks.',
          ));
          break;

        case 'two_column':
          slides.add(Slide(
            id: _uuid.v4(),
            deckId: deckId,
            slideOrder: order,
            layout: 'two_column',
            title: item.title,
            subtitle: 'Direct comparative assessment between approaches',
            leftColumnTitle: 'Conventional Methods',
            leftColumnText:
                'Fragmented point solutions, heavy manual coordination, high latency feedback loops, and escalating maintenance overhead.',
            rightColumnTitle: 'Next-Gen Architecture',
            rightColumnText:
                'Unified intelligent orchestration, autonomous self-healing workflows, real-time feedback, and compounding cost efficiency.',
          ));
          break;

        case 'image_text':
          slides.add(Slide(
            id: _uuid.v4(),
            deckId: deckId,
            slideOrder: order,
            layout: 'image_text',
            title: item.title,
            subtitle: 'Designing for longevity and scalable adoption',
            leftColumnText:
                'Modern architectures prioritize modularity, decoupling complex sub-systems to allow rapid parallel experimentation without compromising system-wide stability.\n\nBy treating intelligence as a composable utility layer, organizations unlock unprecedented velocity while maintaining robust governance and traceability.',
            imageUrl: _getThematicImageUrl('technology abstract architecture'),
            imagePrompt: 'modern architecture',
          ));
          break;

        case 'quote':
          slides.add(Slide(
            id: _uuid.v4(),
            deckId: deckId,
            slideOrder: order,
            layout: 'quote',
            title: item.title,
            quoteText:
                '"The best way to predict the future is to create it through relentless iteration and radical simplicity."',
            quoteAuthor: 'Founding Principles & Vision',
          ));
          break;

        default:
          slides.add(Slide(
            id: _uuid.v4(),
            deckId: deckId,
            slideOrder: order,
            layout: 'bullets',
            title: item.title,
            bullets: [
              'Insightful analysis tailored to $topic.',
              'Strategic alignment across all execution milestones.',
              'Measurable outcomes with sustained competitive advantage.',
            ],
          ));
      }
    }

    return Deck(
      id: deckId,
      title: outline.isNotEmpty ? outline.first.title : topic,
      topic: topic,
      themeId: themeId,
      slides: slides,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  String _getThematicImageUrl(String query) {
    final encoded = Uri.encodeComponent(query.trim());
    return 'https://image.pollinations.ai/prompt/$encoded%20cinematic%20clean%20minimalistic%20presentation%20aesthetic?width=800&height=450&nologo=true';
  }

  String _extractJson(String text) {
    final match = RegExp(r'\[.*\]', dotAll: true).firstMatch(text);
    if (match != null) {
      return match.group(0)!;
    }
    return text.trim();
  }
}
