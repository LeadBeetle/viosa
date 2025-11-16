import 'dart:io';

/// Model representing audio file metadata for the file picker
/// Contains all information needed to display and sort audio files
class AudioFileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime createdDate;
  final DateTime modifiedDate;
  final String extension;

  AudioFileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.createdDate,
    required this.modifiedDate,
    required this.extension,
  });

  /// Create AudioFileInfo from a File
  static Future<AudioFileInfo> fromFile(File file) async {
    final stat = await file.stat();
    final fileName = file.path.split(Platform.pathSeparator).last;
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    return AudioFileInfo(
      path: file.path,
      name: fileName,
      size: stat.size,
      createdDate: stat.changed,
      modifiedDate: stat.modified,
      extension: ext,
    );
  }

  /// Returns file size in megabytes formatted to 2 decimal places
  String get sizeInMB => (size / (1024 * 1024)).toStringAsFixed(2);

  /// Returns file size in kilobytes formatted to 2 decimal places
  String get sizeInKB => (size / 1024).toStringAsFixed(2);

  /// Returns human-readable file size
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '$sizeInKB KB';
    } else {
      return '$sizeInMB MB';
    }
  }

  /// Returns formatted creation date (e.g., "16. Nov 2025, 14:30")
  String get formattedCreatedDate {
    final day = createdDate.day;
    final month = _getMonthName(createdDate.month);
    final year = createdDate.year;
    final hour = createdDate.hour.toString().padLeft(2, '0');
    final minute = createdDate.minute.toString().padLeft(2, '0');
    return '$day. $month $year, $hour:$minute';
  }

  /// Returns formatted modified date (e.g., "16. Nov 2025, 14:30")
  String get formattedModifiedDate {
    final day = modifiedDate.day;
    final month = _getMonthName(modifiedDate.month);
    final year = modifiedDate.year;
    final hour = modifiedDate.hour.toString().padLeft(2, '0');
    final minute = modifiedDate.minute.toString().padLeft(2, '0');
    return '$day. $month $year, $hour:$minute';
  }

  /// Returns short formatted date for list display (e.g., "16.11.2025")
  String get shortFormattedDate {
    final day = createdDate.day.toString().padLeft(2, '0');
    final month = createdDate.month.toString().padLeft(2, '0');
    final year = createdDate.year;
    return '$day.$month.$year';
  }

  /// Helper method to get German month name
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];
    return months[month - 1];
  }

  /// Check if this is an audio file based on extension
  bool get isAudioFile {
    const audioExtensions = [
      'mp3', 'wav', 'm4a', 'mp4', 'aac', 'ogg', 'flac', 'opus', 'wma',
      '3gp', 'amr', 'webm', 'oga', 'spx', 'mid', 'midi', 'mka', 'ape',
      'wv', 'tta', 'ac3', 'dts', 'alac', 'aiff', 'aif', 'aifc', 'caf',
      'pcm', 'raw'
    ];
    return audioExtensions.contains(extension);
  }

  /// Get icon based on file extension
  String get iconName {
    switch (extension) {
      case 'mp3':
        return 'audio_file';
      case 'wav':
        return 'audio_file';
      case 'm4a':
      case 'mp4':
        return 'audio_file';
      default:
        return 'audio_file';
    }
  }
}
