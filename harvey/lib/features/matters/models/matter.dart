import 'contract.dart';

class Matter {
  final String id;
  final String name;
  final String description;
  final List<Contract> contracts;
  final int createdAt;
  final int updatedAt;

  const Matter({
    required this.id,
    required this.name,
    required this.description,
    this.contracts = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Matter copyWith({
    String? id,
    String? name,
    String? description,
    List<Contract>? contracts,
    int? createdAt,
    int? updatedAt,
  }) {
    return Matter(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      contracts: contracts ?? this.contracts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Matter.fromMap(Map<String, dynamic> map, {List<Contract> contracts = const []}) {
    return Matter(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      contracts: contracts,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }
}
