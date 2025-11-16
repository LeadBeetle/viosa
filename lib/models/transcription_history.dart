import 'package:hive/hive.dart';
import 'transcription_result.dart';
import 'prompt_result.dart';

part 'transcription_history.g.dart';

/// Data model for transcription history entry
/// Follows Single Responsibility Principle (SRP)
@HiveType(typeId: 2)
class TranscriptionHistory {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String audioFileName;

  @HiveField(2)
  final TranscriptionResult transcription;

  @HiveField(3)
  final List<PromptResult> promptResults;

  @HiveField(4)
  final DateTime createdAt;

  TranscriptionHistory({
    String? id,
    required this.audioFileName,
    required this.transcription,
    List<PromptResult>? promptResults,
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        promptResults = promptResults ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// Creates history entry from JSON
  factory TranscriptionHistory.fromJson(Map<String, dynamic> json) {
    return TranscriptionHistory(
      id: json['id'] as String,
      audioFileName: json['audioFileName'] as String,
      transcription: TranscriptionResult.fromJson(
        json['transcription'] as Map<String, dynamic>,
      ),
      promptResults: (json['promptResults'] as List<dynamic>?)
              ?.map((e) => PromptResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Converts history entry to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audioFileName': audioFileName,
      'transcription': transcription.toJson(),
      'promptResults': promptResults.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Returns formatted creation timestamp
  String get formattedCreatedAt {
    return '${createdAt.year}-${_twoDigits(createdAt.month)}-${_twoDigits(createdAt.day)} '
        '${_twoDigits(createdAt.hour)}:${_twoDigits(createdAt.minute)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  /// Creates a copy with updated fields
  TranscriptionHistory copyWith({
    String? id,
    String? audioFileName,
    TranscriptionResult? transcription,
    List<PromptResult>? promptResults,
    DateTime? createdAt,
  }) {
    return TranscriptionHistory(
      id: id ?? this.id,
      audioFileName: audioFileName ?? this.audioFileName,
      transcription: transcription ?? this.transcription,
      promptResults: promptResults ?? this.promptResults,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
