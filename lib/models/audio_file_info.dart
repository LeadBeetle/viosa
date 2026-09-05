import 'dart:io';

import '../utils/audio_formats.dart';
import '../utils/file_size_formatter.dart';
import '../utils/path_utils.dart';

/// Metadaten einer Audiodatei für die Dateiauswahl.
class AudioFileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime modifiedDate;
  final String extension;

  AudioFileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.modifiedDate,
    required this.extension,
  });

  /// Erzeugt die Metadaten aus einer Datei.
  static Future<AudioFileInfo> fromFile(File file) async {
    final stat = await file.stat();
    final fileName = PathUtils.fileNameOf(file.path);

    return AudioFileInfo(
      path: file.path,
      name: fileName,
      size: stat.size,
      modifiedDate: stat.modified,
      extension: AudioFormats.extensionOf(fileName),
    );
  }

  /// Menschenlesbare Dateigröße.
  String get formattedSize => FileSizeFormatter.format(size);

  /// Änderungsdatum als "16. Nov 2025, 14:30".
  String get formattedModifiedDate {
    final month = _monthName(modifiedDate.month);
    final hour = modifiedDate.hour.toString().padLeft(2, '0');
    final minute = modifiedDate.minute.toString().padLeft(2, '0');
    return '${modifiedDate.day}. $month ${modifiedDate.year}, $hour:$minute';
  }

  /// Kurzes Änderungsdatum als "16.11.2025".
  String get shortFormattedDate {
    final day = modifiedDate.day.toString().padLeft(2, '0');
    final month = modifiedDate.month.toString().padLeft(2, '0');
    return '$day.$month.${modifiedDate.year}';
  }

  /// Prüft, ob die Erweiterung ein unterstütztes Audioformat bezeichnet.
  bool get isAudioFile => AudioFormats.isSupportedExtension(extension);

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];
    return months[month - 1];
  }
}
