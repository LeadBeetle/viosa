import 'dart:io';
import '../models/audio_file_info.dart';

/// Interface for scanning directories and finding audio files
/// Follows Interface Segregation Principle and Dependency Inversion Principle
abstract class IAudioFileScannerService {
  /// Get common audio directories based on platform
  Future<List<Directory>> getCommonAudioDirectories();

  /// Scan a directory for audio files
  /// Returns list of AudioFileInfo sorted by creation date (newest first)
  Future<List<AudioFileInfo>> scanDirectory(
    Directory directory, {
    bool recursive = false,
    int maxFiles = 500,
  });

  /// Scan multiple directories and combine results
  Future<List<AudioFileInfo>> scanMultipleDirectories(
    List<Directory> directories, {
    bool recursive = false,
    int maxFilesPerDirectory = 200,
  });

  /// Scan a custom directory path
  Future<List<AudioFileInfo>> scanCustomPath(
    String path, {
    bool recursive = false,
    int maxFiles = 500,
  });

  /// Get all audio files from common directories
  Future<List<AudioFileInfo>> getAllAudioFiles({
    bool recursive = false,
    int maxFilesPerDirectory = 200,
  });
}
