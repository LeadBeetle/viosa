import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'i_recording_checkpoint_service.dart';

/// Service for managing recording checkpoints for crash recovery
/// Follows Single Responsibility Principle
class RecordingCheckpointService implements IRecordingCheckpointService {
  static const String _checkpointFileName = 'recording_checkpoint.json';

  Future<File> _getCheckpointFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_checkpointFileName');
  }

  @override
  Future<void> saveCheckpoint({
    required String recordingPath,
    required Duration currentDuration,
  }) async {
    try {
      final checkpoint = RecordingCheckpoint(
        recordingPath: recordingPath,
        duration: currentDuration,
        timestamp: DateTime.now(),
      );

      final file = await _getCheckpointFile();
      await file.writeAsString(jsonEncode(checkpoint.toJson()));
      debugPrint('Checkpoint saved: ${checkpoint.duration.inMinutes} minutes');
    } catch (e) {
      debugPrint('Failed to save checkpoint: $e');
    }
  }

  @override
  Future<RecordingCheckpoint?> loadCheckpoint() async {
    try {
      final file = await _getCheckpointFile();

      if (!await file.exists()) {
        return null;
      }

      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      final checkpoint = RecordingCheckpoint.fromJson(json);

      // Verify the recording file still exists
      final recordingFile = File(checkpoint.recordingPath);
      if (!await recordingFile.exists()) {
        await clearCheckpoint();
        return null;
      }

      return checkpoint;
    } catch (e) {
      debugPrint('Failed to load checkpoint: $e');
      return null;
    }
  }

  @override
  Future<void> clearCheckpoint() async {
    try {
      final file = await _getCheckpointFile();
      if (await file.exists()) {
        await file.delete();
        debugPrint('Checkpoint cleared');
      }
    } catch (e) {
      debugPrint('Failed to clear checkpoint: $e');
    }
  }

  @override
  Future<bool> hasCheckpoint() async {
    try {
      final file = await _getCheckpointFile();
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}
