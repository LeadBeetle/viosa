import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/audio_split.dart';
import '../utils/audio_utils.dart';
import 'i_audio_splitter_service.dart';

/// Service for splitting audio files into smaller segments
/// Following Single Responsibility Principle (SRP)
class AudioSplitterService implements IAudioSplitterService {
  /// Splits an audio file into segments with optional overlap
  /// Returns a list of AudioSplit objects representing each segment
  @override
  Future<List<AudioSplit>> splitAudio(
    String audioPath, {
    Duration maxDuration = const Duration(minutes: 10),
    Duration overlap = const Duration(seconds: 5),
    void Function(SplitProgress progress)? onProgress,
  }) async {
    try {
      // Get total audio duration
      final totalDuration = await AudioUtils.getAudioDuration(audioPath);
      if (totalDuration == Duration.zero) {
        throw Exception('Unable to determine audio duration');
      }

      // Calculate number of splits needed
      final splitCount = await AudioUtils.calculateSplitCount(
        audioPath,
        maxDuration: maxDuration,
        overlap: overlap,
      );

      // If file is short enough, no split needed
      if (splitCount == 1) {
        return [
          await _createSingleSplit(audioPath, totalDuration),
        ];
      }

      // Create temp directory for splits
      final tempDir = await _getTempDirectory();
      final splits = <AudioSplit>[];

      // Calculate equal segment durations
      // Instead of fixed 10-minute segments, distribute the total duration evenly
      final totalMs = totalDuration.inMilliseconds;
      final segmentDuration = Duration(milliseconds: (totalMs / splitCount).ceil());

      for (int i = 0; i < splitCount; i++) {
        onProgress?.call(SplitProgress(
          currentSplit: i,
          totalSplits: splitCount,
          phase: SplitPhase.splitting,
        ));

        // Calculate start time (each segment starts where the previous one started + segmentDuration - overlap)
        final startTime = i == 0
            ? Duration.zero
            : Duration(milliseconds: (i * segmentDuration.inMilliseconds) - overlap.inMilliseconds);

        // For the last split, go to the end of the file
        final endTime = (i == splitCount - 1)
            ? totalDuration
            : Duration(milliseconds: ((i + 1) * segmentDuration.inMilliseconds));

        // Ensure endTime doesn't exceed total duration
        final actualEndTime = endTime > totalDuration ? totalDuration : endTime;

        // Calculate duration for this split
        final splitDuration = actualEndTime - startTime;

        // Generate output filename
        final extension = path.extension(audioPath);
        final outputPath = path.join(
          tempDir.path,
          'split_${DateTime.now().millisecondsSinceEpoch}_${i.toString().padLeft(3, '0')}$extension',
        );

        // Execute FFmpeg split command
        final success = await _executeSplit(
          audioPath,
          outputPath,
          startTime,
          splitDuration,
        );

        if (!success) {
          throw Exception('Failed to create split $i');
        }

        // Get file size
        final file = File(outputPath);
        final size = await file.length();

        // Get MIME type
        final mimeType = AudioUtils.getMimeType(audioPath);

        // Create AudioSplit object
        final split = AudioSplit(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          index: i,
          filePath: outputPath,
          startTimeMs: startTime.inMilliseconds,
          endTimeMs: actualEndTime.inMilliseconds,
          size: size,
          mimeType: mimeType,
        );

        splits.add(split);
      }

      onProgress?.call(SplitProgress(
        currentSplit: splitCount,
        totalSplits: splitCount,
        phase: SplitPhase.finished,
      ));

      return splits;
    } catch (e) {
      throw Exception('Failed to split audio: $e');
    }
  }

  /// Creates a single split for files that don't need splitting
  Future<AudioSplit> _createSingleSplit(String audioPath, Duration duration) async {
    final file = File(audioPath);
    final size = await file.length();
    final mimeType = AudioUtils.getMimeType(audioPath);

    return AudioSplit(
      id: '${DateTime.now().millisecondsSinceEpoch}_0',
      index: 0,
      filePath: audioPath,
      startTimeMs: 0,
      endTimeMs: duration.inMilliseconds,
      size: size,
      mimeType: mimeType,
    );
  }

  /// Executes FFmpeg command to split audio
  Future<bool> _executeSplit(
    String inputPath,
    String outputPath,
    Duration startTime,
    Duration duration,
  ) async {
    try {
      // Format time as HH:MM:SS.mmm
      final startTimeStr = _formatFFmpegTime(startTime);
      final durationStr = _formatFFmpegTime(duration);

      final arguments = [
        '-i', inputPath,
        '-ss', startTimeStr,
        '-t', durationStr,
        '-c', 'copy',
        '-avoid_negative_ts', 'make_zero',
        outputPath,
      ];

      final session = await FFmpegKit.executeWithArguments(arguments);
      final returnCode = await session.getReturnCode();

      return ReturnCode.isSuccess(returnCode);
    } catch (e) {
      return false;
    }
  }

  /// Formats duration for FFmpeg (HH:MM:SS.mmm)
  String _formatFFmpegTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);

    return '${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(seconds)}.${_threeDigits(milliseconds)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
  String _threeDigits(int n) => n.toString().padLeft(3, '0');

  /// Gets temporary directory for storing split files
  Future<Directory> _getTempDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final splitsDir = Directory(path.join(tempDir.path, 'audio_splits'));

    if (!await splitsDir.exists()) {
      await splitsDir.create(recursive: true);
    }

    return splitsDir;
  }

  /// Deletes split files to free up space
  @override
  Future<void> cleanupSplits(List<AudioSplit> splits) async {
    for (final split in splits) {
      try {
        final file = File(split.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
  }

  /// Deletes all split files in the temp directory
  @override
  Future<void> cleanupAllSplits() async {
    try {
      final splitsDir = await _getTempDirectory();
      if (await splitsDir.exists()) {
        await splitsDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignore errors during cleanup
    }
  }

  /// Gets total size of all split files
  @override
  Future<int> getSplitsTotalSize(List<AudioSplit> splits) async {
    int totalSize = 0;
    for (final split in splits) {
      totalSize += split.size;
    }
    return totalSize;
  }
}
