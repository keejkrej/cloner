class Voice {
  final String id;
  final String name;
  final String category; // 'premade' or 'cloned'
  final String description;
  final String? samplePath;
  final int createdAt;

  const Voice({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.samplePath,
    required this.createdAt,
  });

  bool get isCloned => category == 'cloned';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'sample_path': samplePath,
      'created_at': createdAt,
    };
  }

  factory Voice.fromMap(Map<String, dynamic> map) {
    return Voice(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      samplePath: map['sample_path'] as String?,
      createdAt: map['created_at'] as int,
    );
  }

  static const List<Voice> defaultPremadeVoices = [
    Voice(
      id: '21m00Tcm4TlvDq8ikWAM',
      name: 'Rachel',
      category: 'premade',
      description: 'Calm, warm young female (American)',
      createdAt: 0,
    ),
    Voice(
      id: 'pNInz6obpgDQGcFmaJgB',
      name: 'Adam',
      category: 'premade',
      description: 'Deep, smooth middle-aged male (American)',
      createdAt: 0,
    ),
    Voice(
      id: 'ErXwobaYiN019PkySvjV',
      name: 'Antoni',
      category: 'premade',
      description: 'Well-rounded, warm male (American)',
      createdAt: 0,
    ),
    Voice(
      id: 'EXAVITQu4vr4xnSDxMaL',
      name: 'Bella',
      category: 'premade',
      description: 'Expressive, soft female (American)',
      createdAt: 0,
    ),
    Voice(
      id: 'AZnzlk1XvdvUeBnXmlld',
      name: 'Domi',
      category: 'premade',
      description: 'Strong, direct young female (American)',
      createdAt: 0,
    ),
    Voice(
      id: 'TxGEqnHWrfWFTfGW9XjX',
      name: 'Josh',
      category: 'premade',
      description: 'Natural, approachable young male (American)',
      createdAt: 0,
    ),
    Voice(
      id: 'yoZ06aMxZJJ28mfd3POQ',
      name: 'Sam',
      category: 'premade',
      description: 'Dynamic, narrative male (American)',
      createdAt: 0,
    ),
    Voice(
      id: 'piTKgcLEGmPE4e6mEKli',
      name: 'Nicole',
      category: 'premade',
      description: 'Whispering, gentle female (American)',
      createdAt: 0,
    ),
  ];
}
