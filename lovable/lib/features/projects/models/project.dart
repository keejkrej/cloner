class Project {
  final String id;
  final String name;
  final String initialPrompt;
  final String dirPath;
  final int createdAt;
  final int updatedAt;

  const Project({
    required this.id,
    required this.name,
    required this.initialPrompt,
    required this.dirPath,
    required this.createdAt,
    required this.updatedAt,
  });

  Project copyWith({
    String? id,
    String? name,
    String? initialPrompt,
    String? dirPath,
    int? createdAt,
    int? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      initialPrompt: initialPrompt ?? this.initialPrompt,
      dirPath: dirPath ?? this.dirPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initial_prompt': initialPrompt,
      'dir_path': dirPath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      initialPrompt: map['initial_prompt'] as String,
      dirPath: map['dir_path'] as String,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }
}
