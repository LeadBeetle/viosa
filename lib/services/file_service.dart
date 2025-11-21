import 'dart:io';
import 'package:flutter/material.dart';
import '../models/audio_file.dart';
import '../models/audio_file_info.dart';
import '../widgets/custom_audio_file_picker.dart';

/// Interface for file operations
/// Following Interface Segregation Principle (ISP)
abstract class IFileService {
  Future<AudioFile?> pickAudioFile(BuildContext context);
  Future<AudioFile?> reloadAudioFile(AudioFile audioFile);
  Future<AudioFile> renameAudioFile(AudioFile audioFile, String newName);
}

/// Service for handling file operations
/// Single Responsibility Principle (SRP): Only handles file picking
class FileService implements IFileService {

  @override
  Future<AudioFile?> pickAudioFile(BuildContext context) async {
    try {
      // Show custom audio file picker
      final AudioFileInfo? selectedFileInfo = await Navigator.of(context).push<AudioFileInfo>(
        MaterialPageRoute(
          builder: (context) => const CustomAudioFilePicker(),
          fullscreenDialog: true,
        ),
      );

      if (selectedFileInfo == null) {
        return null;
      }

      // Convert AudioFileInfo to AudioFile
      final file = File(selectedFileInfo.path);

      // Validate file exists
      if (!await file.exists()) {
        throw Exception('Datei existiert nicht');
      }

      final fileSize = await file.length();
      final mimeType = _getMimeType(selectedFileInfo.extension);

      return AudioFile(
        path: file.path,
        name: selectedFileInfo.name,
        base64Data: null, // Lazy-loaded when needed for transcription
        mimeType: mimeType,
        size: fileSize,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Reloads an audio file from disk to validate it still exists
  /// Base64Data is no longer pre-loaded to save memory
  @override
  Future<AudioFile?> reloadAudioFile(AudioFile audioFile) async {
    try {
      final file = File(audioFile.path);

      // Validate file exists
      if (!await file.exists()) {
        throw Exception('Datei existiert nicht: ${audioFile.path}');
      }

      // Just verify and return same AudioFile (no need to reload)
      return audioFile;
    } catch (e) {
      rethrow;
    }
  }

  /// Renames an audio file on disk and returns updated AudioFile
  @override
  Future<AudioFile> renameAudioFile(AudioFile audioFile, String newName) async {
    // Rename the actual file on disk
    final oldFile = File(audioFile.path);
    final directory = oldFile.parent.path;
    final newPath = '$directory/$newName.m4a';
    await oldFile.rename(newPath);

    // Create updated AudioFile with new name and path
    return AudioFile(
      path: newPath,
      name: '$newName.m4a',
      base64Data: null, // Lazy-loaded when needed
      mimeType: audioFile.mimeType,
      size: audioFile.size,
    );
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'mp4':
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
      case 'oga':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      case 'opus':
        return 'audio/opus';
      case 'wma':
        return 'audio/x-ms-wma';
      case '3gp':
        return 'audio/3gpp';
      case 'amr':
        return 'audio/amr';
      case 'webm':
        return 'audio/webm';
      case 'spx':
        return 'audio/speex';
      case 'mid':
      case 'midi':
        return 'audio/midi';
      case 'mka':
        return 'audio/x-matroska';
      case 'ape':
        return 'audio/ape';
      case 'wv':
        return 'audio/wavpack';
      case 'tta':
        return 'audio/x-tta';
      case 'ac3':
        return 'audio/ac3';
      case 'dts':
        return 'audio/vnd.dts';
      case 'alac':
        return 'audio/alac';
      case 'aiff':
      case 'aif':
      case 'aifc':
        return 'audio/aiff';
      case 'caf':
        return 'audio/x-caf';
      case 'pcm':
      case 'raw':
        return 'audio/pcm';
      default:
        return 'audio/mpeg';
    }
  }
}
