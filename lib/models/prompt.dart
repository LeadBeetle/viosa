import 'package:hive/hive.dart';

part 'prompt.g.dart';

/// Data model representing a prompt template
/// Follows Single Responsibility Principle (SRP)
@HiveType(typeId: 4)
class Prompt {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String template;

  @HiveField(3)
  final bool isPredefined;

  @HiveField(4)
  final DateTime createdAt;

  Prompt({
    required this.id,
    required this.name,
    required this.template,
    this.isPredefined = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a prompt from JSON
  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'] as String,
      name: json['name'] as String,
      template: json['template'] as String,
      isPredefined: json['isPredefined'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Converts prompt to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'template': template,
      'isPredefined': isPredefined,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy with modified fields
  Prompt copyWith({
    String? id,
    String? name,
    String? template,
    bool? isPredefined,
    DateTime? createdAt,
  }) {
    return Prompt(
      id: id ?? this.id,
      name: name ?? this.name,
      template: template ?? this.template,
      isPredefined: isPredefined ?? this.isPredefined,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
