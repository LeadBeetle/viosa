/// Result of a speech-to-text request
class SpeechToTextResult {
  final String text;
  final String model;

  const SpeechToTextResult({
    required this.text,
    required this.model,
  });
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

  /// Transcribe base64 encoded audio into raw text
  Future<SpeechToTextResult> transcribe({
    required String apiKey,
    required String base64Audio,
    required String format,
    String? language,
  });
}
