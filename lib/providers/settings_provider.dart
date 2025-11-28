import 'package:flutter/material.dart';
import '../services/settings_service.dart';
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
  String _selectedModel = ModelRepository.defaultModelId;
  String _themeMode = 'system';
  bool _speakerDiarization = false;
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
  String get selectedModel => _selectedModel;
  String get themeModeString => _themeMode;
  bool get speakerDiarization => _speakerDiarization;
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
      _selectedModel = await _settingsService.getModel();
      _themeMode = await _settingsService.getThemeMode();
      _speakerDiarization = await _settingsService.getSpeakerDiarization();
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

  /// Save selected model and update state
  Future<void> saveModel(String model) async {
    await _settingsService.saveModel(model);
    _selectedModel = model;
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

  /// Clear all settings
  Future<void> clearSettings() async {
    await _settingsService.clearAllSettings();
    _apiKey = null;
    _language = 'auto';
    _audioSavePath = null;
    _textSize = 16.0;
    _selectedModel = ModelRepository.defaultModelId;
    _themeMode = 'system';
    _speakerDiarization = false;
    notifyListeners();
  }
}
