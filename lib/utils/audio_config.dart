/// Audio recording configuration constants
/// Centralizes audio quality settings to avoid magic numbers across the codebase
class AudioConfig {
  /// Audio bitrate in bits per second (128 kbps)
  /// Higher values = better quality but larger files
  static const int bitRate = 128000;

  /// Audio sample rate in Hz (44.1 kHz - CD quality)
  /// Standard for high-quality audio recording
  static const int sampleRate = 44100;

  /// Default maximum recording duration (10 minutes)
  static const Duration maxRecordingDuration = Duration(minutes: 10);

  /// Default audio file extension for recordings
  static const String recordingExtension = '.m4a';

  /// Audio encoder format
  static const String encoderFormat = 'aac';

  // Prevent instantiation
  AudioConfig._();
}
