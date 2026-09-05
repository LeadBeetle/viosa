import 'package:hive/hive.dart';
import 'speaker.dart';
import 'transcript_segment.dart';

part 'transcription_result.g.dart';

/// Data model representing a transcription result
/// Following Single Responsibility Principle (SRP)
@HiveType(typeId: 0)
class TranscriptionResult {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final String language;

  @HiveField(2)
  final String modelUsed;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final List<Speaker> speakers;

  @HiveField(5)
  final List<TranscriptSegment> segments;

  TranscriptionResult({
    required this.text,
    required this.language,
    required this.modelUsed,
    required this.timestamp,
    List<Speaker>? speakers,
    List<TranscriptSegment>? segments,
  })  : speakers = speakers ?? [],
        segments = segments ?? [];

  /// Returns true if the transcript carries usable segment timestamps
  bool get hasTimestamps => segments.isNotEmpty;

  /// Converts the transcription result to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'language': language,
      'modelUsed': modelUsed,
      'timestamp': timestamp.toIso8601String(),
      'speakers': speakers.map((s) => s.toJson()).toList(),
      'segments': segments.map((s) => s.toJson()).toList(),
    };
  }

  /// Creates a transcription result from a JSON map
  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionResult(
      text: json['text'] as String,
      language: json['language'] as String,
      modelUsed: json['modelUsed'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      speakers: (json['speakers'] as List<dynamic>?)
              ?.map((s) => Speaker.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      segments: (json['segments'] as List<dynamic>?)
              ?.map((s) => TranscriptSegment.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Returns true if multiple speakers were identified
  bool get hasMultipleSpeakers => speakers.length > 1;

  /// Returns formatted timestamp
  String get formattedTimestamp {
    return '${timestamp.year}-${_twoDigits(timestamp.month)}-${_twoDigits(timestamp.day)} '
        '${_twoDigits(timestamp.hour)}:${_twoDigits(timestamp.minute)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  /// Returns language name in human-readable format
  String get languageName {
    switch (language) {
      case 'de':
        return 'Deutsch';
      case 'en':
        return 'English';
      case 'auto':
        return 'Auto-Detect';
      default:
        return language;
    }
  }

  /// Returns character count of the transcription text
  int get characterCount => text.length;

  /// Returns word count of the transcription text
  int get wordCount {
    if (text.isEmpty) return 0;
    return text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }
}
