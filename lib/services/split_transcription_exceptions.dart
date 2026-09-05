/// Base class for errors of the split transcription pipeline
class SplitTranscriptionException implements Exception {
  final String message;

  const SplitTranscriptionException(this.message);

  @override
  String toString() => message;
}

/// Thrown when an operation targets a job that is no longer active
class JobNotFoundException extends SplitTranscriptionException {
  const JobNotFoundException(String jobId) : super('Job not found: $jobId');
}

/// Thrown when a job is started without an API key
class MissingApiKeyException extends SplitTranscriptionException {
  const MissingApiKeyException() : super('API key not set');
}

/// Thrown when a split cannot be retried
class SplitNotRetryableException extends SplitTranscriptionException {
  const SplitNotRetryableException(super.message);
}

/// Thrown when the audio of a job is gone, for example because it was moved
/// or deleted after the history entry was written
class AudioFileMissingException extends SplitTranscriptionException {
  final String path;

  const AudioFileMissingException(this.path)
      : super('Audio file not found: $path');
}

/// Thrown when the length of an audio file cannot be read, so the pipeline
/// cannot decide how to split it
class AudioDurationUnknownException extends SplitTranscriptionException {
  const AudioDurationUnknownException(String path)
      : super('Unable to determine audio duration: $path');
}

/// Thrown when a split could not be cut out of the source audio
class AudioSplitFailedException extends SplitTranscriptionException {
  const AudioSplitFailedException(int index)
      : super('Failed to create split $index');
}
