import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/audio_file.dart';
import '../models/audio_file_info.dart';
import '../widgets/custom_audio_file_picker.dart';

/// Interface for file operations
/// Following Interface Segregation Principle (ISP)
abstract class IFileService {
  Future<AudioFile?> pickAudioFile(BuildContext context);
}

/// Service for handling file operations
/// Single Responsibility Principle (SRP): Only handles file picking and conversion
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

      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);
      final mimeType = _getMimeType(selectedFileInfo.extension);

      return AudioFile(
        path: file.path,
        name: selectedFileInfo.name,
        base64Data: base64Audio,
        mimeType: mimeType,
        size: bytes.length,
      );
    } catch (e) {
      rethrow;
    }
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
