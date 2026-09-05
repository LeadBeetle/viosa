import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/audio_file_info.dart';
import '../utils/audio_formats.dart';
import '../utils/path_utils.dart';
import 'i_audio_file_scanner_service.dart';
import 'settings_service.dart';

/// Durchsucht Verzeichnisse nach Audiodateien.
class AudioFileScannerService implements IAudioFileScannerService {
  static const int _maxScannedEntities = 20000;

  static const List<String> _androidMediaFolders = [
    'Music',
    'Download',
    'Recordings',
    'Voice Recorder',
    'Documents',
    'Audiobooks',
    'Podcasts',
  ];

  final ISettingsService _settingsService;

  AudioFileScannerService({ISettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService();

  @override
  Future<List<Directory>> getCommonAudioDirectories() async {
    final List<Directory> directories = [];
    final Set<String> addedPaths = {};

    void addDirectory(Directory directory) {
      final normalizedPath = PathUtils.normalize(directory.path);
      if (addedPaths.add(normalizedPath)) {
        directories.add(directory);
      }
    }

    try {
      final customPath = await _settingsService.getAudioSavePath();
      if (customPath != null && customPath.isNotEmpty) {
        final customDirectory = Directory(customPath);
        if (await customDirectory.exists()) {
          addDirectory(customDirectory);
        }
      }

      addDirectory(await getApplicationDocumentsDirectory());

      if (Platform.isAndroid) {
        final externalDirectory = await getExternalStorageDirectory();
        final storageRoot = externalDirectory == null
            ? null
            : _getStorageRoot(externalDirectory.path);

        if (storageRoot != null) {
          for (final folder in _androidMediaFolders) {
            final directory = Directory('$storageRoot/$folder');
            if (await directory.exists()) {
              addDirectory(directory);
            }
          }
        }
      } else if (Platform.isIOS) {
        addDirectory(await getTemporaryDirectory());
        addDirectory(await getApplicationSupportDirectory());
        addDirectory(await getLibraryDirectory());
      }
    } catch (e) {
      debugPrint('Error getting audio directories: $e');
    }

    return directories;
  }

  @override
  Future<AudioScanResult> scanDirectory(
    Directory directory, {
    bool recursive = false,
    int maxFiles = 500,
  }) async {
    final List<AudioFileInfo> audioFiles = [];
    bool truncated = false;

    try {
      if (!await directory.exists()) {
        debugPrint('Directory does not exist: ${directory.path}');
        return AudioScanResult.empty;
      }

      int scannedEntities = 0;

      await for (final entity
          in directory.list(recursive: recursive, followLinks: false)) {
        scannedEntities++;
        if (audioFiles.length >= maxFiles ||
            scannedEntities > _maxScannedEntities) {
          truncated = true;
          break;
        }

        if (entity is! File) {
          continue;
        }

        final fileName = PathUtils.fileNameOf(entity.path);
        if (!AudioFormats.isSupportedPath(fileName)) {
          continue;
        }

        try {
          audioFiles.add(await AudioFileInfo.fromFile(entity));
        } catch (e) {
          debugPrint('Could not access file ${entity.path}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory ${directory.path}: $e');
    }

    audioFiles.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));

    return AudioScanResult(files: audioFiles, truncated: truncated);
  }

  @override
  Future<AudioScanResult> scanMultipleDirectories(
    List<Directory> directories, {
    bool recursive = false,
    int maxFilesPerDirectory = 200,
  }) async {
    final List<AudioFileInfo> allAudioFiles = [];
    final Set<String> seenPaths = {};
    bool truncated = false;

    for (final directory in directories) {
      final result = await scanDirectory(
        directory,
        recursive: recursive,
        maxFiles: maxFilesPerDirectory,
      );
      truncated = truncated || result.truncated;

      for (final file in result.files) {
        if (seenPaths.add(PathUtils.normalize(file.path))) {
          allAudioFiles.add(file);
        }
      }
    }

    allAudioFiles.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));

    return AudioScanResult(files: allAudioFiles, truncated: truncated);
  }

  @override
  Future<AudioScanResult> scanCustomPath(
    String path, {
    bool recursive = false,
    int maxFiles = 500,
  }) async {
    final directory = Directory(path);

    if (!await directory.exists()) {
      throw DirectoryNotFoundException(path);
    }

    return scanDirectory(
      directory,
      recursive: recursive,
      maxFiles: maxFiles,
    );
  }

  @override
  Future<AudioScanResult> getAllAudioFiles({
    bool recursive = false,
    int maxFilesPerDirectory = 200,
  }) async {
    final directories = await getCommonAudioDirectories();
    return scanMultipleDirectories(
      directories,
      recursive: recursive,
      maxFilesPerDirectory: maxFilesPerDirectory,
    );
  }

  /// Ermittelt die Speicherwurzel aus dem externen App-Verzeichnis.
  ///
  /// Beispiel: `/storage/emulated/0/Android/data/...` ergibt `/storage/emulated/0`.
  String? _getStorageRoot(String path) {
    if (path.contains('/Android/')) {
      return path.split('/Android/').first;
    }

    final parts = path.split('/');
    if (parts.length >= 4 && parts[1] == 'storage') {
      return '/${parts[1]}/${parts[2]}/${parts[3]}';
    }

    return null;
  }
}
