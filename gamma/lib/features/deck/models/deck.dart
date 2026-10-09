import 'slide.dart';

class Deck {
  final String id;
  final String title;
  final String topic;
  final String themeId;
  final List<Slide> slides;
  final int createdAt;
  final int updatedAt;

  const Deck({
    required this.id,
    required this.title,
    required this.topic,
    required this.themeId,
    this.slides = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Deck copyWith({
    String? id,
    String? title,
    String? topic,
    String? themeId,
    List<Slide>? slides,
    int? createdAt,
    int? updatedAt,
  }) {
    return Deck(
      id: id ?? this.id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      themeId: themeId ?? this.themeId,
      slides: slides ?? this.slides,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'topic': topic,
      'theme_id': themeId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Deck.fromMap(Map<String, dynamic> map, {List<Slide> slides = const []}) {
    return Deck(
      id: map['id'] as String,
      title: map['title'] as String,
      topic: map['topic'] as String,
      themeId: map['theme_id'] as String,
      slides: slides,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }
}
