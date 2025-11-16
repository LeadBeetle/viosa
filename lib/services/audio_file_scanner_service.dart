import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/audio_file_info.dart';

/// Service for scanning directories and finding audio files
/// Follows Single Responsibility Principle: Only handles file system scanning
class AudioFileScannerService {
  static const List<String> _supportedExtensions = [
    'mp3',   // MPEG Audio Layer 3
    'wav',   // Waveform Audio File
    'mp4',   // MPEG-4 Part 14
    'm4a',   // MPEG-4 Audio
    'aac',   // Advanced Audio Coding
    'ogg',   // Ogg Vorbis
    'flac',  // Free Lossless Audio Codec
    'opus',  // Opus Audio Codec
    'wma',   // Windows Media Audio
    '3gp',   // 3GPP Multimedia
    'amr',   // Adaptive Multi-Rate
    'webm',  // WebM Audio
    'oga',   // Ogg Audio
    'spx',   // Speex
    'mid',   // MIDI
    'midi',  // MIDI
    'mka',   // Matroska Audio
    'ape',   // Monkey's Audio
    'wv',    // WavPack
    'tta',   // True Audio
    'ac3',   // Dolby Digital
    'dts',   // DTS Audio
    'alac',  // Apple Lossless
    'aiff',  // Audio Interchange File Format
    'aif',   // Audio Interchange File Format
    'aifc',  // AIFF Compressed
    'caf',   // Core Audio Format
    'pcm',   // Pulse Code Modulation
    'raw',   // Raw Audio
  ];

  /// Get common audio directories based on platform
  Future<List<Directory>> getCommonAudioDirectories() async {
    final List<Directory> directories = [];

    try {
      if (Platform.isAndroid) {
        // On Android, try to access common media directories
        // Note: Android 11+ has scoped storage restrictions
        final externalDir = await getExternalStorageDirectory();

        if (externalDir != null) {
          // Try to navigate to common directories
          final storageRoot = _getStorageRoot(externalDir.path);

          if (storageRoot != null) {
            // Add Music directory
            final musicDir = Directory('$storageRoot/Music');
            if (await musicDir.exists()) {
              directories.add(musicDir);
            }

            // Add Downloads directory
            final downloadsDir = Directory('$storageRoot/Download');
            if (await downloadsDir.exists()) {
              directories.add(downloadsDir);
            }

            // Add Recordings directory
            final recordingsDir = Directory('$storageRoot/Recordings');
            if (await recordingsDir.exists()) {
              directories.add(recordingsDir);
            }

            // Add Voice Recorder directory
            final voiceRecorderDir = Directory('$storageRoot/Voice Recorder');
            if (await voiceRecorderDir.exists()) {
              directories.add(voiceRecorderDir);
            }
          }
        }
      } else if (Platform.isIOS) {
        // On iOS, use documents directory
        final appDocDir = await getApplicationDocumentsDirectory();
        directories.add(appDocDir);
      }
    } catch (e) {
      // If we can't access standard directories, return empty list
      // Silent fail - return empty list
    }

    return directories;
  }

  /// Extract storage root from external storage path
  /// Example: /storage/emulated/0/Android/data/... -> /storage/emulated/0
  String? _getStorageRoot(String path) {
    try {
      if (path.contains('/Android/')) {
        return path.split('/Android/')[0];
      }
      // Fallback for different Android versions
      final parts = path.split('/');
      if (parts.length >= 4 && parts[1] == 'storage') {
        return '/${parts[1]}/${parts[2]}/${parts[3]}';
      }
    } catch (e) {
      // Silent fail - return null
    }
    return null;
  }

  /// Scan a directory for audio files
  /// Returns list of AudioFileInfo sorted by creation date (newest first)
  Future<List<AudioFileInfo>> scanDirectory(
    Directory directory, {
    bool recursive = false,
    int maxFiles = 500,
  }) async {
    final List<AudioFileInfo> audioFiles = [];

    try {
      final entities = directory.listSync(
        recursive: recursive,
        followLinks: false,
      );

      for (final entity in entities) {
        if (audioFiles.length >= maxFiles) break;

        if (entity is File) {
          // Extract extension more robustly
          final fileName = entity.path.split(Platform.pathSeparator).last;

          if (fileName.contains('.')) {
            final extension = fileName.split('.').last.toLowerCase();

            if (_supportedExtensions.contains(extension)) {
              try {
                final audioFileInfo = await AudioFileInfo.fromFile(entity);
                audioFiles.add(audioFileInfo);
              } catch (e) {
                // Skip files that can't be accessed
              }
            }
          }
        }
      }

      // Sort by creation date (newest first)
      audioFiles.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    } catch (e) {
      // Silent fail - return empty list
    }

    return audioFiles;
  }

  /// Scan multiple directories and combine results
  Future<List<AudioFileInfo>> scanMultipleDirectories(
    List<Directory> directories, {
    bool recursive = false,
    int maxFilesPerDirectory = 200,
  }) async {
    final List<AudioFileInfo> allAudioFiles = [];

    for (final directory in directories) {
      final files = await scanDirectory(
        directory,
        recursive: recursive,
        maxFiles: maxFilesPerDirectory,
      );
      allAudioFiles.addAll(files);
    }

    // Sort combined results by creation date (newest first)
    allAudioFiles.sort((a, b) => b.createdDate.compareTo(a.createdDate));

    return allAudioFiles;
  }

  /// Scan a custom directory path
  Future<List<AudioFileInfo>> scanCustomPath(
    String path, {
    bool recursive = false,
    int maxFiles = 500,
  }) async {
    try {
      final directory = Directory(path);

      if (!await directory.exists()) {
        throw Exception('Verzeichnis existiert nicht: $path');
      }

      return await scanDirectory(
        directory,
        recursive: recursive,
        maxFiles: maxFiles,
      );
    } catch (e) {
      // Silent fail - return empty list
      return [];
    }
  }

  /// Get all audio files from common directories
  Future<List<AudioFileInfo>> getAllAudioFiles({
    bool recursive = false,
    int maxFilesPerDirectory = 200,
  }) async {
    final directories = await getCommonAudioDirectories();
    return await scanMultipleDirectories(
      directories,
      recursive: recursive,
      maxFilesPerDirectory: maxFilesPerDirectory,
    );
  }
}
