import '../models/transcription_options.dart';
import '../models/transcription_result.dart';

/// Interface for transcribing a complete audio file in one request
abstract class ITranscriptionJobService {
  /// Transcribes the audio at [audioPath] and retries transient failures
  Future<TranscriptionResult> transcribeFile({
    required String audioPath,
    required String apiKey,
    required String language,
    required TranscriptionOptions options,
    String? model,
  });
}
