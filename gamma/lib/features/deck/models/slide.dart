import 'dart:convert';

enum SlideLayout {
  title('title', 'Title Slide'),
  bullets('bullets', 'Key Takeaways & Bullets'),
  twoColumn('two_column', 'Two-Column Comparison'),
  imageText('image_text', 'Image & Text Focus'),
  bigNumber('big_number', 'Big Metric / Number'),
  quote('quote', 'Quote & Callout');

  final String code;
  final String label;
  const SlideLayout(this.code, this.label);

  static SlideLayout fromCode(String code) {
    return SlideLayout.values.firstWhere(
      (e) => e.code == code,
      orElse: () => SlideLayout.bullets,
    );
  }
}

class Slide {
  final String id;
  final String deckId;
  final int slideOrder;
  final String layout; // code from SlideLayout
  final String title;
  final String? subtitle;
  final List<String> bullets;
  final String? leftColumnTitle;
  final String? leftColumnText;
  final String? rightColumnTitle;
  final String? rightColumnText;
  final String? statNumber;
  final String? statLabel;
  final String? quoteText;
  final String? quoteAuthor;
  final String? imageUrl;
  final String? imagePrompt;

  const Slide({
    required this.id,
    required this.deckId,
    required this.slideOrder,
    required this.layout,
    required this.title,
    this.subtitle,
    this.bullets = const [],
    this.leftColumnTitle,
    this.leftColumnText,
    this.rightColumnTitle,
    this.rightColumnText,
    this.statNumber,
    this.statLabel,
    this.quoteText,
    this.quoteAuthor,
    this.imageUrl,
    this.imagePrompt,
  });

  SlideLayout get layoutType => SlideLayout.fromCode(layout);

  Slide copyWith({
    String? id,
    String? deckId,
    int? slideOrder,
    String? layout,
    String? title,
    String? subtitle,
    List<String>? bullets,
    String? leftColumnTitle,
    String? leftColumnText,
    String? rightColumnTitle,
    String? rightColumnText,
    String? statNumber,
    String? statLabel,
    String? quoteText,
    String? quoteAuthor,
    String? imageUrl,
    String? imagePrompt,
  }) {
    return Slide(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      slideOrder: slideOrder ?? this.slideOrder,
      layout: layout ?? this.layout,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      bullets: bullets ?? this.bullets,
      leftColumnTitle: leftColumnTitle ?? this.leftColumnTitle,
      leftColumnText: leftColumnText ?? this.leftColumnText,
      rightColumnTitle: rightColumnTitle ?? this.rightColumnTitle,
      rightColumnText: rightColumnText ?? this.rightColumnText,
      statNumber: statNumber ?? this.statNumber,
      statLabel: statLabel ?? this.statLabel,
      quoteText: quoteText ?? this.quoteText,
      quoteAuthor: quoteAuthor ?? this.quoteAuthor,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePrompt: imagePrompt ?? this.imagePrompt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'slide_order': slideOrder,
      'layout': layout,
      'title': title,
      'subtitle': subtitle,
      'bullets_json': jsonEncode(bullets),
      'left_column_title': leftColumnTitle,
      'left_column_text': leftColumnText,
      'right_column_title': rightColumnTitle,
      'right_column_text': rightColumnText,
      'stat_number': statNumber,
      'stat_label': statLabel,
      'quote_text': quoteText,
      'quote_author': quoteAuthor,
      'image_url': imageUrl,
      'image_prompt': imagePrompt,
    };
  }

  factory Slide.fromMap(Map<String, dynamic> map) {
    List<String> bulletsList = [];
    if (map['bullets_json'] != null && (map['bullets_json'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(map['bullets_json'] as String);
        if (decoded is List) {
          bulletsList = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return Slide(
      id: map['id'] as String,
      deckId: map['deck_id'] as String,
      slideOrder: map['slide_order'] as int,
      layout: map['layout'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String?,
      bullets: bulletsList,
      leftColumnTitle: map['left_column_title'] as String?,
      leftColumnText: map['left_column_text'] as String?,
      rightColumnTitle: map['right_column_title'] as String?,
      rightColumnText: map['right_column_text'] as String?,
      statNumber: map['stat_number'] as String?,
      statLabel: map['stat_label'] as String?,
      quoteText: map['quote_text'] as String?,
      quoteAuthor: map['quote_author'] as String?,
      imageUrl: map['image_url'] as String?,
      imagePrompt: map['image_prompt'] as String?,
    );
  }
}
