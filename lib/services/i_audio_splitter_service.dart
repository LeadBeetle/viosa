import '../models/audio_split.dart';

/// Progress information for audio splitting operation
class SplitProgress {
  final int currentSplit;
  final int totalSplits;
  final String? currentStatus;

  const SplitProgress({
    required this.currentSplit,
    required this.totalSplits,
    this.currentStatus,
  });

  double get progress => totalSplits > 0 ? currentSplit / totalSplits : 0.0;
  int get progressPercentage => (progress * 100).round();
}

/// Interface for splitting audio files into smaller segments
/// Follows Interface Segregation Principle and Dependency Inversion Principle
abstract class IAudioSplitterService {
  /// Splits an audio file into segments with optional overlap
  /// Returns a list of AudioSplit objects representing each segment
  Future<List<AudioSplit>> splitAudio(
    String audioPath, {
    Duration maxDuration = const Duration(minutes: 10),
    Duration overlap = const Duration(seconds: 5),
    void Function(SplitProgress progress)? onProgress,
  });

  /// Deletes split files to free up space
  Future<void> cleanupSplits(List<AudioSplit> splits);

  /// Deletes all split files in the temp directory
  Future<void> cleanupAllSplits();

  /// Gets total size of all split files
  Future<int> getSplitsTotalSize(List<AudioSplit> splits);
}
