import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';

/// Utility class for audio file operations
/// Following Single Responsibility Principle (SRP)
class AudioUtils {
  /// Gets the duration of an audio file
  /// Returns Duration.zero if unable to determine duration
  static Future<Duration> getAudioDuration(String filePath) async {
    try {
      // Verify file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: $filePath');
      }

      // Use just_audio to get duration
      final player = AudioPlayer();
      try {
        await player.setFilePath(filePath);

        // Wait for duration to become available
        // The duration might not be immediately available after setFilePath
        Duration? duration = player.duration;
        duration ??= await player.durationStream
            .firstWhere((d) => d != null, orElse: () => Duration.zero)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () => Duration.zero,
            );

        return duration ?? Duration.zero;
      } finally {
        await player.dispose();
      }
    } catch (e) {
      debugPrint('Error getting audio duration: $e');
      return Duration.zero;
    }
  }

  /// Checks if an audio file is longer than the specified duration
  static Future<bool> isLongerThan(String filePath, Duration threshold) async {
    final duration = await getAudioDuration(filePath);
    return duration > threshold;
  }

  /// Checks if an audio file should be split based on max duration
  /// Default max duration is 10 minutes
  static Future<bool> shouldSplit(
    String filePath, {
    Duration maxDuration = const Duration(minutes: 10),
  }) async {
    return isLongerThan(filePath, maxDuration);
  }

  /// Calculates the number of splits needed for an audio file
  /// Ensures splits are evenly distributed with no split exceeding maxDuration
  static Future<int> calculateSplitCount(
    String filePath, {
    Duration maxDuration = const Duration(minutes: 10),
    Duration overlap = const Duration(seconds: 5),
  }) async {
    final duration = await getAudioDuration(filePath);
    if (duration == Duration.zero) return 1;
    if (duration <= maxDuration) return 1;

    final splitCount = (duration.inMilliseconds / maxDuration.inMilliseconds).ceil();
    return splitCount.clamp(1, 999);
  }

  /// Formats a duration as a human-readable string (HH:MM:SS or MM:SS)
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
    } else {
      return '${_twoDigits(minutes)}:${_twoDigits(seconds)}';
    }
  }

  /// Formats a duration as a short human-readable string (e.g., "42m 30s")
  static String formatDurationShort(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');

  /// Gets file size in bytes
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return 0;
      }
      return await file.length();
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return 0;
    }
  }

  /// Formats file size in human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Validates if a file is a supported audio format
  static bool isSupportedAudioFormat(String filePath) {
    final supportedExtensions = [
      '.mp3',
      '.wav',
      '.m4a',
      '.mp4',
      '.aac',
      '.ogg',
      '.flac',
      '.opus',
      '.wma',
      '.3gp',
      '.amr',
      '.webm',
      '.oga',
      '.spx',
      '.mid',
      '.midi',
      '.mka',
      '.ape',
      '.wv',
      '.tta',
      '.ac3',
      '.dts',
      '.alac',
      '.aiff',
      '.caf',
      '.pcm',
    ];

    final extension = filePath.toLowerCase().substring(filePath.lastIndexOf('.'));
    return supportedExtensions.contains(extension);
  }

  /// Gets MIME type from file extension
  static String getMimeType(String filePath) {
    final extension = filePath.toLowerCase().substring(filePath.lastIndexOf('.'));

    switch (extension) {
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.m4a':
      case '.mp4':
        return 'audio/mpeg'; // OpenRouter expects audio/mpeg for M4A
      case '.aac':
        return 'audio/aac';
      case '.ogg':
      case '.oga':
        return 'audio/ogg';
      case '.flac':
        return 'audio/flac';
      case '.opus':
        return 'audio/opus';
      case '.webm':
        return 'audio/webm';
      default:
        return 'audio/mpeg'; // Default fallback
    }
  }
}
