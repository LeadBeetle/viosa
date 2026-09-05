import 'dart:io';

import '../models/audio_file_info.dart';

/// Ergebnis eines Verzeichnis-Scans.
///
/// Meldet zusätzlich, ob das Limit erreicht wurde, damit die Oberfläche
/// eine unvollständige Liste kenntlich machen kann.
class AudioScanResult {
  final List<AudioFileInfo> files;
  final bool truncated;

  const AudioScanResult({
    required this.files,
    this.truncated = false,
  });

  static const AudioScanResult empty =
      AudioScanResult(files: <AudioFileInfo>[], truncated: false);
}

/// Schnittstelle für das Durchsuchen von Verzeichnissen nach Audiodateien.
abstract class IAudioFileScannerService {
  /// Verzeichnisse, die je nach Plattform durchsucht werden.
  Future<List<Directory>> getCommonAudioDirectories();

  /// Durchsucht ein Verzeichnis nach Audiodateien.
  Future<AudioScanResult> scanDirectory(
    Directory directory, {
    bool recursive = false,
    int maxFiles = 500,
  });

  /// Durchsucht mehrere Verzeichnisse und führt die Ergebnisse zusammen.
  Future<AudioScanResult> scanMultipleDirectories(
    List<Directory> directories, {
    bool recursive = false,
    int maxFilesPerDirectory = 200,
  });

  /// Durchsucht einen frei gewählten Pfad.
  ///
  /// Wirft eine [DirectoryNotFoundException], wenn das Verzeichnis fehlt.
  Future<AudioScanResult> scanCustomPath(
    String path, {
    bool recursive = false,
    int maxFiles = 500,
  });

  /// Liefert alle Audiodateien aus den bekannten Verzeichnissen.
  Future<AudioScanResult> getAllAudioFiles({
    bool recursive = false,
    int maxFilesPerDirectory = 200,
  });
}

/// Fehler, wenn ein zu durchsuchendes Verzeichnis nicht existiert.
class DirectoryNotFoundException implements Exception {
  final String path;

  const DirectoryNotFoundException(this.path);

  @override
  String toString() => 'Verzeichnis existiert nicht: $path';
}
