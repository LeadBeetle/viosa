import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/transcription/i_speech_to_text_service.dart';
import '../services/i_locale_service.dart';
import '../services/locale_service.dart';
import '../repositories/model_repository.dart';

/// Provider for app-wide settings state management
/// Wraps SettingsService and provides reactive state updates
class SettingsProvider with ChangeNotifier {
  final ISettingsService _settingsService;
  final ILocaleService _localeService;

  String? _apiKey;
  String _language = 'auto';
  String _uiLanguage = 'de';
  String? _audioSavePath;
  double _textSize = 16.0;
  String _themeMode = 'system';
  bool _speakerDiarization = false;
  TranscribeStyle _transcribeStyle = TranscribeStyle.clean;
  List<String> _keywords = const [];
  bool _autoTranscribe = false;
  String? _autoPromptId;
  bool _isInitialized = false;
  bool _isLoading = false;

  SettingsProvider(this._settingsService, {ILocaleService? localeService})
      : _localeService = localeService ?? LocaleService();

  // Getters
  String? get apiKey => _apiKey;
  String get language => _language;
  String get uiLanguage => _uiLanguage;
  Locale get locale => Locale(_uiLanguage);
  String? get audioSavePath => _audioSavePath;
  double get textSize => _textSize;
  String get completionModelId => ModelRepository.defaultModelId;
  String get transcriptionModelId => ModelRepository.transcriptionModelId;
  String get themeModeString => _themeMode;
  bool get speakerDiarization => _speakerDiarization;
  TranscribeStyle get transcribeStyle => _transcribeStyle;
  List<String> get keywords => List.unmodifiable(_keywords);
  bool get autoTranscribe => _autoTranscribe;
  String? get autoPromptId => _autoPromptId;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  ThemeMode get themeMode {
    switch (_themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Initialize settings from storage on app startup
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      _apiKey = await _settingsService.getApiKey();
      _language = await _settingsService.getLanguage();
      _uiLanguage = await _localeService.getUiLanguage();
      _audioSavePath = await _settingsService.getAudioSavePath();
      _textSize = await _settingsService.getTextSize();
      _themeMode = await _settingsService.getThemeMode();
      _speakerDiarization = await _settingsService.getSpeakerDiarization();
      _transcribeStyle = await _settingsService.getTranscribeStyle();
      _keywords = await _settingsService.getKeywords();
      _autoTranscribe = await _settingsService.getAutoTranscribe();
      _autoPromptId = await _settingsService.getAutoPromptId();
      await _settingsService.removeLegacySettings();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save API key and update state
  Future<void> saveApiKey(String apiKey) async {
    await _settingsService.saveApiKey(apiKey);
    _apiKey = apiKey;
    notifyListeners();
  }

  /// Save language preference and update state
  Future<void> saveLanguage(String language) async {
    await _settingsService.saveLanguage(language);
    _language = language;
    notifyListeners();
  }

  /// Save audio save path and update state
  Future<void> saveAudioSavePath(String path) async {
    await _settingsService.saveAudioSavePath(path);
    _audioSavePath = path;
    notifyListeners();
  }

  /// Save text size and update state
  Future<void> saveTextSize(double size) async {
    await _settingsService.saveTextSize(size);
    _textSize = size;
    notifyListeners();
  }

  /// Save theme mode and update state
  Future<void> saveThemeMode(String themeMode) async {
    await _settingsService.saveThemeMode(themeMode);
    _themeMode = themeMode;
    notifyListeners();
  }

  /// Save UI language and update state
  Future<void> saveUiLanguage(String language) async {
    await _localeService.saveUiLanguage(language);
    _uiLanguage = language;
    notifyListeners();
  }

  /// Save speaker diarization setting and update state
  Future<void> saveSpeakerDiarization(bool enabled) async {
    await _settingsService.saveSpeakerDiarization(enabled);
    _speakerDiarization = enabled;
    notifyListeners();
  }

  /// Save the transcript style requested from the speech-to-text model
  Future<void> saveTranscribeStyle(TranscribeStyle style) async {
    await _settingsService.saveTranscribeStyle(style);
    _transcribeStyle = style;
    notifyListeners();
  }

  /// Save the keywords used to bias recognition towards domain terms
  Future<void> saveKeywords(List<String> keywords) async {
    await _settingsService.saveKeywords(keywords);
    _keywords = await _settingsService.getKeywords();
    notifyListeners();
  }

  /// Save whether a finished recording starts transcription on its own
  Future<void> saveAutoTranscribe(bool enabled) async {
    await _settingsService.saveAutoTranscribe(enabled);
    _autoTranscribe = enabled;
    notifyListeners();
  }

  /// Save the prompt that runs on its own once a transcription is done
  Future<void> saveAutoPromptId(String? promptId) async {
    await _settingsService.saveAutoPromptId(promptId);
    _autoPromptId = promptId;
    notifyListeners();
  }

  /// Clear all settings
  Future<void> clearSettings() async {
    await _settingsService.clearAllSettings();
    _apiKey = null;
    _language = 'auto';
    _audioSavePath = null;
    _textSize = 16.0;
    _themeMode = 'system';
    _speakerDiarization = false;
    _transcribeStyle = TranscribeStyle.clean;
    _keywords = const [];
    _autoTranscribe = false;
    _autoPromptId = null;
    notifyListeners();
  }
}
