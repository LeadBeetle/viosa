import '../../models/transcript_segment.dart';

/// Transcription styles supported by the speech-to-text model
enum TranscribeStyle {
  /// Removes fillers and repetitions
  clean('clean'),

  /// Keeps fillers, repetitions and false starts
  verbatim('verbatim');

  const TranscribeStyle(this.wireValue);

  /// Value the provider API expects
  final String wireValue;

  /// Returns the style [wireValue] stands for, `null` if it is unknown
  static TranscribeStyle? fromWireValue(String? wireValue) {
    for (final style in values) {
      if (style.wireValue == wireValue) return style;
    }
    return null;
  }
}

/// Result of a speech-to-text request
class SpeechToTextResult {
  final String text;
  final String model;

  /// Language the model detected, `null` if the API reported none
  final String? detectedLanguage;

  /// Time coded segments, empty if the API returned none
  final List<TranscriptSegment> segments;

  const SpeechToTextResult({
    required this.text,
    required this.model,
    this.detectedLanguage,
    this.segments = const [],
  });

  /// Returns true if the model assigned speaker labels to the segments
  bool get hasSpeakerLabels =>
      segments.any((s) => s.speaker != null && s.speaker!.isNotEmpty);
}

/// Interface for speech-to-text services
/// Follows Single Responsibility: Only handles audio to raw text conversion
abstract class ISpeechToTextService {
  /// Unique identifier for this provider (e.g., 'openrouter')
  String get providerId;

  /// Human-readable provider name
  String get providerName;

  /// The speech-to-text model ID being used
  String get model;

  /// Transcribe base64 encoded audio
  ///
  /// [diarization] requests speaker labels from the model,
  /// [phrases] biases recognition towards domain specific terms and
  /// [transcribeStyle] selects a verbatim or cleaned transcript.
  Future<SpeechToTextResult> transcribe({
    required String apiKey,
    required String base64Audio,
    required String format,
    String? language,
    bool diarization = false,
    List<String> phrases = const [],
    TranscribeStyle? transcribeStyle,
  });
}
