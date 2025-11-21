/// Interface for recording checkpoint service
/// Provides crash recovery for long recordings
abstract class IRecordingCheckpointService {
  /// Saves a checkpoint for the current recording
  Future<void> saveCheckpoint({
    required String recordingPath,
    required Duration currentDuration,
  });

  /// Loads the most recent checkpoint if available
  Future<RecordingCheckpoint?> loadCheckpoint();

  /// Clears all checkpoints
  Future<void> clearCheckpoint();

  /// Checks if there is a checkpoint available for recovery
  Future<bool> hasCheckpoint();
}

/// Data model for recording checkpoint
class RecordingCheckpoint {
  final String recordingPath;
  final Duration duration;
  final DateTime timestamp;

  RecordingCheckpoint({
    required this.recordingPath,
    required this.duration,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'recordingPath': recordingPath,
      'duration': duration.inSeconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RecordingCheckpoint.fromJson(Map<String, dynamic> json) {
    return RecordingCheckpoint(
      recordingPath: json['recordingPath'] as String,
      duration: Duration(seconds: json['duration'] as int),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
