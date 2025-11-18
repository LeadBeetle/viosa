import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';

/// Provider for app-wide settings state management
/// Wraps SettingsService and provides reactive state updates
class SettingsProvider with ChangeNotifier {
  final ISettingsService _settingsService;

  String? _apiKey;
  String _language = 'auto';
  String? _audioSavePath;
  double _textSize = 16.0; // Default text size
  String _selectedModel = 'google/gemini-2.5-flash'; // Default model
  bool _isInitialized = false;
  bool _isLoading = false;

  SettingsProvider(this._settingsService);

  // Getters
  String? get apiKey => _apiKey;
  String get language => _language;
  String? get audioSavePath => _audioSavePath;
  double get textSize => _textSize;
  String get selectedModel => _selectedModel;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// Initialize settings from storage on app startup
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      _apiKey = await _settingsService.getApiKey();
      _language = await _settingsService.getLanguage();
      _audioSavePath = await _settingsService.getAudioSavePath();
      _textSize = await _settingsService.getTextSize();
      _selectedModel = await _settingsService.getModel();
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

  /// Clear all settings
  Future<void> clearSettings() async {
    await _settingsService.clearAllSettings();
    _apiKey = null;
    _language = 'auto';
    _audioSavePath = null;
    _textSize = 16.0;
    _selectedModel = 'google/gemini-2.5-flash';
    notifyListeners();
  }
}
