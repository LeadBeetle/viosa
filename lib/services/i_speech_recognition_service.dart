/// Interface for speech recognition services
/// Follows Interface Segregation Principle (ISP)
abstract class ISpeechRecognitionService {
  /// Initialize the speech recognition service
  /// Returns true if initialization was successful
  Future<bool> initialize();

  /// Check if speech recognition is available on this device
  Future<bool> get isAvailable;

  /// Check if the service is currently listening
  bool get isListening;

  /// Start listening for speech input
  /// [onResult] is called with the final recognized text
  /// [onPartialResult] is called with interim results while speaking
  /// [locale] specifies the language for recognition (default: German)
  Future<void> startListening({
    required void Function(String text) onResult,
    required void Function(String text) onPartialResult,
    String locale = 'de-DE',
  });

  /// Stop listening and finalize recognition
  Future<void> stopListening();

  /// Cancel listening without finalizing
  Future<void> cancelListening();

  /// Dispose of resources
  void dispose();
}
