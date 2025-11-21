import 'package:hive/hive.dart';

part 'audio_file.g.dart';

/// Data model representing an audio file
/// Following Single Responsibility Principle (SRP)
@HiveType(typeId: 3)
class AudioFile {
  @HiveField(0)
  final String path;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? base64Data;

  @HiveField(3)
  final String mimeType;

  @HiveField(4)
  final int size;

  AudioFile({
    required this.path,
    required this.name,
    required this.base64Data,
    required this.mimeType,
    required this.size,
  });

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

  /// Returns file extension from the name
  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  /// Converts the audio file to a JSON map
  /// Note: base64Data is excluded from JSON to prevent Out of Memory errors
  /// during session restoration. The file can be re-read from the path when needed.
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      // 'base64Data': base64Data,  // Excluded to prevent OOM
      'mimeType': mimeType,
      'size': size,
    };
  }

  /// Creates an audio file from a JSON map
  /// Note: base64Data is null by default and should be loaded from path when needed
  factory AudioFile.fromJson(Map<String, dynamic> json) {
    return AudioFile(
      path: json['path'] as String,
      name: json['name'] as String,
      base64Data: json['base64Data'] as String?,  // Null if not present
      mimeType: json['mimeType'] as String,
      size: json['size'] as int,
    );
  }
}
