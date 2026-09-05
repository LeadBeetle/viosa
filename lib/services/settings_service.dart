import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Interface for settings storage operations
/// Following Interface Segregation Principle (ISP)
abstract class ISettingsService {
  Future<void> saveApiKey(String apiKey);
  Future<String?> getApiKey();
  Future<void> deleteApiKey();
  Future<void> saveLanguage(String language);
  Future<String> getLanguage();
  Future<void> deleteLanguage();
  Future<bool> hasApiKey();
  Future<void> saveAudioSavePath(String path);
  Future<String?> getAudioSavePath();
  Future<void> deleteAudioSavePath();
  Future<void> saveTextSize(double size);
  Future<double> getTextSize();
  Future<void> saveThemeMode(String themeMode);
  Future<String> getThemeMode();
  Future<void> saveSpeakerDiarization(bool enabled);
  Future<bool> getSpeakerDiarization();
  Future<void> clearAllSettings();
}

/// Concrete implementation of settings service
/// Single Responsibility Principle (SRP): Only handles settings storage
class SettingsService implements ISettingsService {
  final FlutterSecureStorage _storage;

  static const String _apiKeyKey = 'openrouter_api_key';
  static const String _languageKey = 'transcription_language';
  static const String _audioSavePathKey = 'audio_save_path';
  static const String _textSizeKey = 'text_size';
  /// Legacy key, only removed on clear
  static const String _modelKey = 'selected_model';
  static const String _themeModeKey = 'theme_mode';
  static const String _speakerDiarizationKey = 'speaker_diarization';
  static const String _defaultLanguage = 'auto';
  static const double _defaultTextSize = 16.0;
  static const String _defaultThemeMode = 'system';
  static const bool _defaultSpeakerDiarization = false;

  SettingsService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> saveApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      throw ArgumentError('API key cannot be empty');
    }
    await _storage.write(key: _apiKeyKey, value: apiKey);
  }

  @override
  Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyKey);
  }

  @override
  Future<void> saveLanguage(String language) async {
    final validLanguages = ['auto', 'de', 'en'];
    if (!validLanguages.contains(language)) {
      throw ArgumentError('Invalid language: $language');
    }
    await _storage.write(key: _languageKey, value: language);
  }

  @override
  Future<String> getLanguage() async {
    return await _storage.read(key: _languageKey) ?? _defaultLanguage;
  }

  @override
  Future<bool> hasApiKey() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  @override
  Future<void> saveAudioSavePath(String path) async {
    if (path.trim().isEmpty) {
      throw ArgumentError('Audio save path cannot be empty');
    }
    await _storage.write(key: _audioSavePathKey, value: path);
  }

  @override
  Future<String?> getAudioSavePath() async {
    return await _storage.read(key: _audioSavePathKey);
  }

  @override
  Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyKey);
  }

  @override
  Future<void> deleteLanguage() async {
    await _storage.delete(key: _languageKey);
  }

  @override
  Future<void> deleteAudioSavePath() async {
    await _storage.delete(key: _audioSavePathKey);
  }

  @override
  Future<void> saveTextSize(double size) async {
    if (size < 12.0 || size > 24.0) {
      throw ArgumentError('Text size must be between 12 and 24');
    }
    await _storage.write(key: _textSizeKey, value: size.toString());
  }

  @override
  Future<double> getTextSize() async {
    final sizeStr = await _storage.read(key: _textSizeKey);
    if (sizeStr == null) return _defaultTextSize;
    return double.tryParse(sizeStr) ?? _defaultTextSize;
  }

  @override
  Future<void> saveThemeMode(String themeMode) async {
    final validThemeModes = ['system', 'light', 'dark'];
    if (!validThemeModes.contains(themeMode)) {
      throw ArgumentError('Invalid theme mode: $themeMode');
    }
    await _storage.write(key: _themeModeKey, value: themeMode);
  }

  @override
  Future<String> getThemeMode() async {
    return await _storage.read(key: _themeModeKey) ?? _defaultThemeMode;
  }

  @override
  Future<void> saveSpeakerDiarization(bool enabled) async {
    await _storage.write(key: _speakerDiarizationKey, value: enabled.toString());
  }

  @override
  Future<bool> getSpeakerDiarization() async {
    final value = await _storage.read(key: _speakerDiarizationKey);
    if (value == null) return _defaultSpeakerDiarization;
    return value == 'true';
  }

  @override
  Future<void> clearAllSettings() async {
    await Future.wait([
      _storage.delete(key: _apiKeyKey),
      _storage.delete(key: _languageKey),
      _storage.delete(key: _audioSavePathKey),
      _storage.delete(key: _textSizeKey),
      _storage.delete(key: _modelKey),
      _storage.delete(key: _themeModeKey),
      _storage.delete(key: _speakerDiarizationKey),
    ]);
  }
}
