import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';

import 'audio_formats.dart';
import 'file_size_formatter.dart';

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

  /// Formatiert eine Dateigröße menschenlesbar
  static String formatFileSize(int bytes) => FileSizeFormatter.format(bytes);

  /// Prüft, ob eine Datei ein unterstütztes Audioformat besitzt
  static bool isSupportedAudioFormat(String filePath) =>
      AudioFormats.isSupportedPath(filePath);

  /// Liefert den MIME-Typ zu einer Dateiendung
  static String getMimeType(String filePath) =>
      AudioFormats.mimeTypeForPath(filePath);
}
