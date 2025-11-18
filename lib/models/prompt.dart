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

  @HiveField(5)
  final int usageCount;

  @HiveField(6)
  final DateTime? lastUsedAt;

  Prompt({
    required this.id,
    required this.name,
    required this.template,
    this.isPredefined = false,
    DateTime? createdAt,
    this.usageCount = 0,
    this.lastUsedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a prompt from JSON
  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'] as String,
      name: json['name'] as String,
      template: json['template'] as String,
      isPredefined: json['isPredefined'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      usageCount: json['usageCount'] as int? ?? 0,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
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
      'usageCount': usageCount,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  /// Creates a copy with modified fields
  Prompt copyWith({
    String? id,
    String? name,
    String? template,
    bool? isPredefined,
    DateTime? createdAt,
    int? usageCount,
    DateTime? lastUsedAt,
  }) {
    return Prompt(
      id: id ?? this.id,
      name: name ?? this.name,
      template: template ?? this.template,
      isPredefined: isPredefined ?? this.isPredefined,
      createdAt: createdAt ?? this.createdAt,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}
