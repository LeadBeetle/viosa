import 'package:hive/hive.dart';

part 'audio_split.g.dart';

/// Status of an audio split transcription
@HiveType(typeId: 5)
enum SplitStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  processing,

  @HiveField(2)
  completed,

  @HiveField(3)
  failed,
}

/// Data model representing a single split of an audio file
/// Following Single Responsibility Principle (SRP)
@HiveType(typeId: 6)
class AudioSplit {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int index;

  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final int startTimeMs;

  @HiveField(4)
  final int endTimeMs;

  @HiveField(5)
  final int size;

  @HiveField(6)
  final String mimeType;

  @HiveField(7)
  SplitStatus status;

  @HiveField(8)
  int attemptCount;

  @HiveField(9)
  String? transcriptionText;

  @HiveField(10)
  String? errorMessage;

  @HiveField(11)
  DateTime? completedAt;

  AudioSplit({
    required this.id,
    required this.index,
    required this.filePath,
    required this.startTimeMs,
    required this.endTimeMs,
    required this.size,
    required this.mimeType,
    this.status = SplitStatus.pending,
    this.attemptCount = 0,
    this.transcriptionText,
    this.errorMessage,
    this.completedAt,
  });

  /// Returns start time as Duration
  Duration get startTime => Duration(milliseconds: startTimeMs);

  /// Returns end time as Duration
  Duration get endTime => Duration(milliseconds: endTimeMs);

  /// Returns formatted time range (e.g., "10:00 - 20:00")
  String get timeRange {
    return '${_formatDuration(startTime)} - ${_formatDuration(endTime)}';
  }

  /// Returns duration of this split
  Duration get duration => endTime - startTime;

  /// Returns human-readable status text
  String get statusText {
    switch (status) {
      case SplitStatus.pending:
        return 'Pending';
      case SplitStatus.processing:
        return 'Processing';
      case SplitStatus.completed:
        return 'Completed';
      case SplitStatus.failed:
        return 'Failed';
    }
  }

  /// Returns whether this split can be retried
  bool get canRetry => status == SplitStatus.failed;

  /// Returns word count of transcription (if available)
  int? get wordCount {
    if (transcriptionText == null) return null;
    return transcriptionText!.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
    } else {
      return '${_twoDigits(minutes)}:${_twoDigits(seconds)}';
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'index': index,
      'filePath': filePath,
      'startTimeMs': startTimeMs,
      'endTimeMs': endTimeMs,
      'size': size,
      'mimeType': mimeType,
      'status': status.name,
      'attemptCount': attemptCount,
      'transcriptionText': transcriptionText,
      'errorMessage': errorMessage,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// Creates from JSON
  factory AudioSplit.fromJson(Map<String, dynamic> json) {
    return AudioSplit(
      id: json['id'] as String,
      index: json['index'] as int,
      filePath: json['filePath'] as String,
      startTimeMs: json['startTimeMs'] as int,
      endTimeMs: json['endTimeMs'] as int,
      size: json['size'] as int,
      mimeType: json['mimeType'] as String,
      status: SplitStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SplitStatus.pending,
      ),
      attemptCount: json['attemptCount'] as int? ?? 0,
      transcriptionText: json['transcriptionText'] as String?,
      errorMessage: json['errorMessage'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  /// Creates a copy with updated fields
  AudioSplit copyWith({
    String? id,
    int? index,
    String? filePath,
    int? startTimeMs,
    int? endTimeMs,
    int? size,
    String? mimeType,
    SplitStatus? status,
    int? attemptCount,
    String? transcriptionText,
    String? errorMessage,
    DateTime? completedAt,
  }) {
    return AudioSplit(
      id: id ?? this.id,
      index: index ?? this.index,
      filePath: filePath ?? this.filePath,
      startTimeMs: startTimeMs ?? this.startTimeMs,
      endTimeMs: endTimeMs ?? this.endTimeMs,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      transcriptionText: transcriptionText ?? this.transcriptionText,
      errorMessage: errorMessage ?? this.errorMessage,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
