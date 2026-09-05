import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/audio_file.dart';
import '../models/audio_file_info.dart';
import '../utils/audio_formats.dart';
import '../utils/path_utils.dart';
import '../widgets/custom_audio_file_picker.dart';
import 'i_file_service.dart';
import 'settings_service.dart';

/// Fehler beim Übernehmen oder Laden einer Audiodatei.
class AudioFileException implements Exception {
  final String message;

  const AudioFileException(this.message);

  @override
  String toString() => message;
}

/// Dateioperationen für Audiodateien.
class FileService implements IFileService {
  static const String _importDirectoryName = 'imports';

  final ISettingsService _settingsService;

  FileService({ISettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService();

  @override
  Future<AudioFile?> pickAudioFile(BuildContext context) async {
    final AudioFileInfo? selectedFileInfo =
        await Navigator.of(context).push<AudioFileInfo>(
      MaterialPageRoute(
        builder: (context) => const CustomAudioFilePicker(),
        fullscreenDialog: true,
      ),
    );

    if (selectedFileInfo == null) {
      return null;
    }

    return importFile(selectedFileInfo.path, displayName: selectedFileInfo.name);
  }

  @override
  Future<AudioFile> importFile(String sourcePath, {String? displayName}) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const AudioFileException('Datei existiert nicht');
    }

    final name = displayName ?? PathUtils.fileNameOf(sourcePath);
    final file = await _keepInAppStorage(source, name);

    return AudioFile(
      path: file.path,
      name: PathUtils.fileNameOf(file.path),
      base64Data: null,
      mimeType: AudioFormats.mimeTypeForPath(file.path),
      size: await file.length(),
    );
  }

  @override
  Future<AudioFile?> reloadAudioFile(AudioFile audioFile) async {
    final file = File(audioFile.path);
    if (!await file.exists()) {
      throw AudioFileException('Datei existiert nicht: ${audioFile.path}');
    }
    return audioFile;
  }

  Future<File> _keepInAppStorage(File source, String displayName) async {
    if (await _isInStableLocation(source.path)) {
      return source;
    }

    final targetDirectory = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/$_importDirectoryName',
    );
    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    final target = _uniqueTarget(targetDirectory, displayName);
    return source.copy(target.path);
  }

  Future<bool> _isInStableLocation(String path) async {
    final normalizedPath = PathUtils.normalize(path);

    final appDocumentsPath =
        PathUtils.normalize((await getApplicationDocumentsDirectory()).path);
    if (normalizedPath.startsWith('$appDocumentsPath/')) {
      return true;
    }

    final customPath = await _settingsService.getAudioSavePath();
    if (customPath != null && customPath.isNotEmpty) {
      final normalizedCustomPath = PathUtils.normalize(customPath);
      if (normalizedPath.startsWith('$normalizedCustomPath/')) {
        return true;
      }
    }

    return false;
  }

  File _uniqueTarget(Directory directory, String displayName) {
    final sanitized = PathUtils.sanitizeFileName(displayName);
    final dotIndex = sanitized.lastIndexOf('.');
    final baseName = dotIndex > 0 ? sanitized.substring(0, dotIndex) : sanitized;
    final extension = dotIndex > 0 ? sanitized.substring(dotIndex) : '';

    File candidate = File('${directory.path}/$sanitized');
    int counter = 1;
    while (candidate.existsSync()) {
      candidate = File('${directory.path}/$baseName ($counter)$extension');
      counter++;
    }
    return candidate;
  }
}
