/// Audio recording configuration constants
/// Centralizes audio quality settings to avoid magic numbers across the codebase
class AudioConfig {
  /// Audio bitrate in bits per second (128 kbps)
  /// Higher values = better quality but larger files
  static const int bitRate = 128000;

  /// Audio sample rate in Hz (16 kHz)
  /// Speech recognition works on 16 kHz, and it keeps the uploaded WAV small
  static const int sampleRate = 16000;

  /// Mono, because speech models mix a stereo track down anyway
  static const int numChannels = 1;

  /// Default maximum recording duration (10 minutes)
  static const Duration maxRecordingDuration = Duration(minutes: 10);

  /// Default audio file extension for recordings
  ///
  /// The transcription provider rejects the MP4/AAC container, so recordings
  /// are written as uncompressed WAV
  static const String recordingExtension = '.wav';

  /// Audio encoder format
  static const String encoderFormat = 'wav';

  // Prevent instantiation
  AudioConfig._();
}
