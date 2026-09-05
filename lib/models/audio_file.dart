import 'package:hive/hive.dart';

import '../utils/audio_formats.dart';
import '../utils/file_size_formatter.dart';

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

  /// Menschenlesbare Dateigröße
  String get formattedSize => FileSizeFormatter.format(size);

  /// Dateiendung ohne führenden Punkt
  String get extension => AudioFormats.extensionOf(name);

  /// Converts the audio file to a JSON map
  /// Note: base64Data is excluded from JSON to prevent Out of Memory errors
  /// during session restoration. The file can be re-read from the path when needed.
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
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
      base64Data: json['base64Data'] as String?,
      mimeType: json['mimeType'] as String,
      size: json['size'] as int,
    );
  }
}
