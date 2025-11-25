import 'package:hive/hive.dart';
import 'audio_split.dart';
import '../services/text_merger_service.dart';

part 'split_transcription_job.g.dart';

/// Status of a split transcription job
@HiveType(typeId: 7)
enum JobStatus {
  @HiveField(0)
  queued,

  @HiveField(1)
  processing,

  @HiveField(2)
  completed,

  @HiveField(3)
  partialFailure,

  @HiveField(4)
  cancelled,
}

/// Data model representing a job that transcribes a split audio file
/// Following Single Responsibility Principle (SRP)
@HiveType(typeId: 8)
class SplitTranscriptionJob {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String originalAudioPath;

  @HiveField(2)
  final String originalFileName;

  @HiveField(3)
  final int totalSplits;

  @HiveField(4)
  final List<AudioSplit> splits;

  @HiveField(5)
  final String language;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  JobStatus status;

  @HiveField(8)
  int completedCount;

  @HiveField(9)
  int failedCount;

  @HiveField(10)
  DateTime? completedAt;

  @HiveField(11)
  DateTime? lastUpdatedAt;

  SplitTranscriptionJob({
    required this.id,
    required this.originalAudioPath,
    required this.originalFileName,
    required this.totalSplits,
    required this.splits,
    required this.language,
    required this.createdAt,
    this.status = JobStatus.queued,
    this.completedCount = 0,
    this.failedCount = 0,
    this.completedAt,
    this.lastUpdatedAt,
  });

  /// Returns progress as a value between 0.0 and 1.0
  double get progress {
    if (totalSplits == 0) return 0.0;
    return completedCount / totalSplits;
  }

  /// Returns progress percentage (0-100)
  int get progressPercentage => (progress * 100).round();

  /// Returns whether all splits have been processed (completed or failed)
  bool get isFinished {
    return completedCount + failedCount == totalSplits;
  }

  /// Returns whether the job has any failures
  bool get hasFailures => failedCount > 0;

  /// Returns whether all splits completed successfully
  bool get isFullySuccessful => completedCount == totalSplits && failedCount == 0;

  /// Returns the number of pending splits
  int get pendingCount {
    return splits.where((s) => s.status == SplitStatus.pending).length;
  }

  /// Returns the number of processing splits
  int get processingCount {
    return splits.where((s) => s.status == SplitStatus.processing).length;
  }

  /// Returns the current split being processed (if any)
  AudioSplit? get currentSplit {
    return splits.firstWhere(
      (s) => s.status == SplitStatus.processing,
      orElse: () => splits.firstWhere(
        (s) => s.status == SplitStatus.pending,
        orElse: () => splits.first,
      ),
    );
  }

  /// Returns merged transcription from all completed splits
  /// Uses TextMergerService to remove duplicate content from overlapping regions
  String? get mergedTranscription {
    if (completedCount == 0) return null;

    final sortedSplits = List<AudioSplit>.from(splits)
      ..sort((a, b) => a.index.compareTo(b.index));

    final successfulTexts = <String>[];
    final failedSegments = <String>[];

    for (final split in sortedSplits) {
      if (split.status == SplitStatus.completed && split.transcriptionText != null) {
        successfulTexts.add(split.transcriptionText!);
      } else if (split.status == SplitStatus.failed) {
        failedSegments.add('[Segment ${split.index + 1} (${split.timeRange}) - Transkription fehlgeschlagen]');
      }
    }

    if (successfulTexts.isEmpty && failedSegments.isEmpty) {
      return null;
    }

    final merger = TextMergerService();
    final mergedText = merger.mergeTexts(successfulTexts);

    if (failedSegments.isEmpty) {
      return mergedText;
    }

    return '$mergedText\n\n${failedSegments.join('\n\n')}';
  }

  /// Returns list of failed splits
  List<AudioSplit> get failedSplits {
    return splits.where((s) => s.status == SplitStatus.failed).toList();
  }

  /// Returns human-readable status text
  String get statusText {
    switch (status) {
      case JobStatus.queued:
        return 'Queued';
      case JobStatus.processing:
        return 'Processing';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.partialFailure:
        return 'Partial Failure';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Returns estimated time remaining based on average time per split
  Duration? estimateTimeRemaining() {
    if (completedCount == 0) return null;

    final elapsed = DateTime.now().difference(createdAt);
    final averageTimePerSplit = elapsed.inMilliseconds / completedCount;
    final remainingSplits = totalSplits - completedCount - failedCount;

    if (remainingSplits <= 0) return Duration.zero;

    return Duration(milliseconds: (averageTimePerSplit * remainingSplits).round());
  }

  /// Returns formatted estimated time remaining
  String? get estimatedTimeRemainingText {
    final estimate = estimateTimeRemaining();
    if (estimate == null) return null;

    final minutes = estimate.inMinutes;
    final seconds = estimate.inSeconds.remainder(60);

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalAudioPath': originalAudioPath,
      'originalFileName': originalFileName,
      'totalSplits': totalSplits,
      'splits': splits.map((s) => s.toJson()).toList(),
      'language': language,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'completedCount': completedCount,
      'failedCount': failedCount,
      'completedAt': completedAt?.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
    };
  }

  /// Creates from JSON
  factory SplitTranscriptionJob.fromJson(Map<String, dynamic> json) {
    return SplitTranscriptionJob(
      id: json['id'] as String,
      originalAudioPath: json['originalAudioPath'] as String,
      originalFileName: json['originalFileName'] as String,
      totalSplits: json['totalSplits'] as int,
      splits: (json['splits'] as List)
          .map((s) => AudioSplit.fromJson(s as Map<String, dynamic>))
          .toList(),
      language: json['language'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: JobStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => JobStatus.queued,
      ),
      completedCount: json['completedCount'] as int? ?? 0,
      failedCount: json['failedCount'] as int? ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? DateTime.parse(json['lastUpdatedAt'] as String)
          : null,
    );
  }

  /// Creates a copy with updated fields
  SplitTranscriptionJob copyWith({
    String? id,
    String? originalAudioPath,
    String? originalFileName,
    int? totalSplits,
    List<AudioSplit>? splits,
    String? language,
    DateTime? createdAt,
    JobStatus? status,
    int? completedCount,
    int? failedCount,
    DateTime? completedAt,
    DateTime? lastUpdatedAt,
  }) {
    return SplitTranscriptionJob(
      id: id ?? this.id,
      originalAudioPath: originalAudioPath ?? this.originalAudioPath,
      originalFileName: originalFileName ?? this.originalFileName,
      totalSplits: totalSplits ?? this.totalSplits,
      splits: splits ?? this.splits,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      completedCount: completedCount ?? this.completedCount,
      failedCount: failedCount ?? this.failedCount,
      completedAt: completedAt ?? this.completedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}
