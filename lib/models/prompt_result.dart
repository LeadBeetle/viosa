import 'package:hive/hive.dart';

part 'prompt_result.g.dart';

/// Data model representing the result of applying a prompt to a transcription
/// Follows Single Responsibility Principle (SRP)
@HiveType(typeId: 1)
class PromptResult {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String promptName;

  @HiveField(2)
  final String promptTemplate;

  @HiveField(3)
  final String transcriptionText;

  @HiveField(4)
  final String llmResponse;

  @HiveField(5)
  final String modelUsed;

  @HiveField(6)
  final DateTime timestamp;

  PromptResult({
    String? id,
    required this.promptName,
    required this.promptTemplate,
    required this.transcriptionText,
    required this.llmResponse,
    required this.modelUsed,
    DateTime? timestamp,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  /// Creates a prompt result from JSON
  factory PromptResult.fromJson(Map<String, dynamic> json) {
    return PromptResult(
      id: json['id'] as String,
      promptName: json['promptName'] as String,
      promptTemplate: json['promptTemplate'] as String,
      transcriptionText: json['transcriptionText'] as String,
      llmResponse: json['llmResponse'] as String,
      modelUsed: json['modelUsed'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Converts prompt result to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'promptName': promptName,
      'promptTemplate': promptTemplate,
      'transcriptionText': transcriptionText,
      'llmResponse': llmResponse,
      'modelUsed': modelUsed,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Returns formatted timestamp
  String get formattedTimestamp {
    return '${timestamp.year}-${_twoDigits(timestamp.month)}-${_twoDigits(timestamp.day)} '
        '${_twoDigits(timestamp.hour)}:${_twoDigits(timestamp.minute)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
