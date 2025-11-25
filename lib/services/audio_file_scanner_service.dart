import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/audio_file_info.dart';
import 'i_audio_file_scanner_service.dart';
import 'settings_service.dart';

/// Service for scanning directories and finding audio files
/// Follows Single Responsibility Principle: Only handles file system scanning
class AudioFileScannerService implements IAudioFileScannerService {
  final ISettingsService _settingsService = SettingsService();
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
  @override
  Future<List<Directory>> getCommonAudioDirectories() async {
    final List<Directory> directories = [];
    final Set<String> addedPaths = {}; // Track added paths to avoid duplicates

    try {
      // Add custom save path from settings if configured
      final customPath = await _settingsService.getAudioSavePath();
      if (customPath != null && customPath.isNotEmpty) {
        final customDir = Directory(customPath);
        if (await customDir.exists()) {
          final normalizedPath = _normalizePath(customDir.path);
          if (!addedPaths.contains(normalizedPath)) {
            directories.add(customDir);
            addedPaths.add(normalizedPath);
          }
        }
      }

      // Always add application documents directory (where recordings are saved by default)
      final appDocDir = await getApplicationDocumentsDirectory();
      final normalizedAppDocPath = _normalizePath(appDocDir.path);
      if (!addedPaths.contains(normalizedAppDocPath)) {
        directories.add(appDocDir);
        addedPaths.add(normalizedAppDocPath);
      }

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
              final normalizedPath = _normalizePath(musicDir.path);
              if (!addedPaths.contains(normalizedPath)) {
                directories.add(musicDir);
                addedPaths.add(normalizedPath);
              }
            }

            // Add Downloads directory
            final downloadsDir = Directory('$storageRoot/Download');
            if (await downloadsDir.exists()) {
              final normalizedPath = _normalizePath(downloadsDir.path);
              if (!addedPaths.contains(normalizedPath)) {
                directories.add(downloadsDir);
                addedPaths.add(normalizedPath);
              }
            }

            // Add Recordings directory
            final recordingsDir = Directory('$storageRoot/Recordings');
            if (await recordingsDir.exists()) {
              final normalizedPath = _normalizePath(recordingsDir.path);
              if (!addedPaths.contains(normalizedPath)) {
                directories.add(recordingsDir);
                addedPaths.add(normalizedPath);
              }
            }

            // Add Voice Recorder directory
            final voiceRecorderDir = Directory('$storageRoot/Voice Recorder');
            if (await voiceRecorderDir.exists()) {
              final normalizedPath = _normalizePath(voiceRecorderDir.path);
              if (!addedPaths.contains(normalizedPath)) {
                directories.add(voiceRecorderDir);
                addedPaths.add(normalizedPath);
              }
            }
          }
        }
      } else if (Platform.isIOS) {
        // On iOS, access is sandboxed - add available app directories
        // iOS apps can only access their own sandbox directories

        // Add temporary directory (for cached/temporary audio files)
        final tempDir = await getTemporaryDirectory();
        final normalizedTempPath = _normalizePath(tempDir.path);
        if (!addedPaths.contains(normalizedTempPath)) {
          directories.add(tempDir);
          addedPaths.add(normalizedTempPath);
        }

        // Add application support directory
        final appSupportDir = await getApplicationSupportDirectory();
        final normalizedAppSupportPath = _normalizePath(appSupportDir.path);
        if (!addedPaths.contains(normalizedAppSupportPath)) {
          directories.add(appSupportDir);
          addedPaths.add(normalizedAppSupportPath);
        }

        // Add library directory for any cached audio
        final libDir = await getLibraryDirectory();
        final normalizedLibPath = _normalizePath(libDir.path);
        if (!addedPaths.contains(normalizedLibPath)) {
          directories.add(libDir);
          addedPaths.add(normalizedLibPath);
        }
      }
    } catch (e) {
      // If we can't access standard directories, return what we have
      // Log error for debugging but don't throw
      debugPrint('Error getting audio directories: $e');
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

  /// Normalize a path to ensure consistent comparison
  /// Handles trailing slashes and case sensitivity on Windows
  String _normalizePath(String path) {
    // Remove trailing slashes/backslashes
    String normalized = path.replaceAll(RegExp(r'[/\\]+$'), '');

    // On Windows, paths are case-insensitive
    if (Platform.isWindows) {
      normalized = normalized.toLowerCase();
    }

    // Replace backslashes with forward slashes for consistency
    normalized = normalized.replaceAll('\\', '/');

    return normalized;
  }

  /// Scan a directory for audio files
  /// Returns list of AudioFileInfo sorted by creation date (newest first)
  @override
  Future<List<AudioFileInfo>> scanDirectory(
    Directory directory, {
    bool recursive = false,
    int maxFiles = 500,
  }) async {
    final List<AudioFileInfo> audioFiles = [];

    try {
      // Check if directory exists before scanning
      if (!await directory.exists()) {
        debugPrint('Directory does not exist: ${directory.path}');
        return audioFiles;
      }

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
                debugPrint('Could not access file ${entity.path}: $e');
              }
            }
          }
        }
      }

      // Sort by creation date (newest first)
      audioFiles.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    } catch (e) {
      // Log error but return what we have so far
      debugPrint('Error scanning directory ${directory.path}: $e');
    }

    return audioFiles;
  }

  /// Scan multiple directories and combine results
  @override
  Future<List<AudioFileInfo>> scanMultipleDirectories(
    List<Directory> directories, {
    bool recursive = false,
    int maxFilesPerDirectory = 200,
  }) async {
    final List<AudioFileInfo> allAudioFiles = [];
    final Set<String> seenPaths = {}; // Track file paths to avoid duplicates

    for (final directory in directories) {
      final files = await scanDirectory(
        directory,
        recursive: recursive,
        maxFiles: maxFilesPerDirectory,
      );

      // Add only unique files based on normalized file path
      for (final file in files) {
        final normalizedPath = _normalizePath(file.path);
        if (!seenPaths.contains(normalizedPath)) {
          allAudioFiles.add(file);
          seenPaths.add(normalizedPath);
        }
      }
    }

    // Sort combined results by creation date (newest first)
    allAudioFiles.sort((a, b) => b.createdDate.compareTo(a.createdDate));

    return allAudioFiles;
  }

  /// Scan a custom directory path
  @override
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
  @override
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
