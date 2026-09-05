import '../services/transcription/i_speech_to_text_service.dart';

/// Options that steer a single transcription request
/// Keeps the diarization, keyword and style settings together so they no
/// longer travel as separate parameters through every layer
class TranscriptionOptions {
  /// Requests speaker labels from the speech-to-text model
  final bool speakerDiarization;

  /// Terms the recognition is biased towards
  final List<String> keywords;

  /// Verbatim or cleaned transcript
  final TranscribeStyle style;

  /// Builds the localized label of the speaker at [position], starting at 1
  final String Function(int position) speakerLabel;

  const TranscriptionOptions({
    required this.speakerLabel,
    this.speakerDiarization = false,
    this.keywords = const [],
    this.style = TranscribeStyle.clean,
  });
}
