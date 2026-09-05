/// Base class for errors of the transcription pipeline
class TranscriptionPipelineException implements Exception {
  final String message;

  const TranscriptionPipelineException(this.message);

  @override
  String toString() => message;
}

/// Thrown when a transcription is started without an API key
class MissingApiKeyException extends TranscriptionPipelineException {
  const MissingApiKeyException() : super('API key not set');
}

/// Thrown when the audio of a job is gone, for example because it was moved
/// or deleted after the history entry was written
class AudioFileMissingException extends TranscriptionPipelineException {
  final String path;

  const AudioFileMissingException(this.path)
      : super('Audio file not found: $path');
}
