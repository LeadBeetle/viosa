import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Interface for audio conversion operations
/// Following Interface Segregation Principle (ISP)
abstract class IAudioConverterService {
  Future<String> convertToMp3(String inputPath);
  Future<void> deleteConvertedFile(String path);
}

/// Service for converting audio files to MP3 format
/// Uses native Android/iOS capabilities for efficient conversion
/// Single Responsibility Principle (SRP): Only handles audio conversion
class AudioConverterService implements IAudioConverterService {
  static const MethodChannel _channel = MethodChannel('com.example.viosa/audio_converter');

  /// Convert an audio file to MP3 format
  /// [inputPath] The path to the input audio file
  /// Returns the path to the converted MP3 file
  @override
  Future<String> convertToMp3(String inputPath) async {
    try {
      debugPrint('Converting audio file to MP3: $inputPath');

      // Generate output path in temp directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${tempDir.path}/converted_$timestamp.mp3';

      debugPrint('Output path: $outputPath');

      // Call native platform code to convert
      final String? result = await _channel.invokeMethod('convertToMp3', {
        'inputPath': inputPath,
        'outputPath': outputPath,
      });

      if (result == null) {
        throw Exception('Conversion failed: No result returned');
      }

      // Verify the output file exists
      final outputFile = File(result);
      if (!await outputFile.exists()) {
        throw Exception('Conversion failed: Output file not created');
      }

      final fileSize = await outputFile.length();
      debugPrint('Conversion completed successfully. Output size: ${_formatBytes(fileSize)}');

      return result;
    } on PlatformException catch (e) {
      debugPrint('Platform error during conversion: ${e.message}');
      throw Exception('Audio conversion failed: ${e.message}');
    } catch (e) {
      debugPrint('Error during conversion: $e');
      throw Exception('Audio conversion failed: $e');
    }
  }

  /// Delete a converted audio file to free up space
  /// [path] The path to the file to delete
  @override
  Future<void> deleteConvertedFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted converted file: $path');
      }
    } catch (e) {
      debugPrint('Error deleting converted file: $e');
      // Don't throw - file cleanup is not critical
    }
  }

  /// Format bytes to human-readable format
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}
