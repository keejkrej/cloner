class GeneratedImage {
  final String id;
  final String prompt;
  final String enhancedPrompt;
  final String aspectRatio;
  final String imagePath;
  final DateTime createdAt;

  GeneratedImage({
    required this.id,
    required this.prompt,
    required this.enhancedPrompt,
    required this.aspectRatio,
    required this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'prompt': prompt,
    'enhanced_prompt': enhancedPrompt,
    'aspect_ratio': aspectRatio,
    'image_path': imagePath,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory GeneratedImage.fromMap(Map<String, dynamic> map) => GeneratedImage(
    id: map['id'] as String,
    prompt: map['prompt'] as String,
    enhancedPrompt: map['enhanced_prompt'] as String,
    aspectRatio: map['aspect_ratio'] as String,
    imagePath: map['image_path'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}
