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
