import 'package:hive/hive.dart';

part 'transcript_segment.g.dart';

/// Ein zeitlich verorteter Abschnitt eines Transkripts.
@HiveType(typeId: 9)
class TranscriptSegment {
  @HiveField(0)
  final int startMs;

  @HiveField(1)
  final int endMs;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final String? speaker;

  const TranscriptSegment({
    required this.startMs,
    required this.endMs,
    required this.text,
    this.speaker,
  });

  Duration get start => Duration(milliseconds: startMs);

  Duration get end => Duration(milliseconds: endMs);

  /// Returns a copy shifted by [offset], used when merging split transcriptions
  TranscriptSegment shiftedBy(Duration offset) {
    return TranscriptSegment(
      startMs: startMs + offset.inMilliseconds,
      endMs: endMs + offset.inMilliseconds,
      text: text,
      speaker: speaker,
    );
  }

  TranscriptSegment copyWith({String? speaker}) {
    return TranscriptSegment(
      startMs: startMs,
      endMs: endMs,
      text: text,
      speaker: speaker ?? this.speaker,
    );
  }

  Map<String, dynamic> toJson() => {
        'startMs': startMs,
        'endMs': endMs,
        'text': text,
        'speaker': speaker,
      };

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      startMs: json['startMs'] as int,
      endMs: json['endMs'] as int,
      text: json['text'] as String,
      speaker: json['speaker'] as String?,
    );
  }
}
