import 'package:flutter/foundation.dart';
import '../models/transcription_history.dart';
import '../services/history_service.dart';

/// Provider for transcription history state management
/// Wraps HistoryService and provides reactive state updates
class HistoryProvider with ChangeNotifier {
  final IHistoryService _historyService;

  List<TranscriptionHistory> _history = [];
  bool _isInitialized = false;
  bool _isLoading = false;

  HistoryProvider(this._historyService);

  // Getters
  List<TranscriptionHistory> get history => List.unmodifiable(_history);
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isEmpty => _history.isEmpty;
  int get count => _history.length;

  /// Initialize history from storage on app startup
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Initialize the history service (opens Hive box and migrates data)
      await _historyService.initialize();
      _history = await _historyService.getAllHistory();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing history: $e');
      _history = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add or update a transcription history entry
  Future<void> saveHistory(TranscriptionHistory history) async {
    await _historyService.saveHistory(history);

    // Reload history to reflect changes
    await _reload();
  }

  /// Delete a history entry
  Future<void> deleteHistory(String id) async {
    await _historyService.deleteHistory(id);
    _history.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// Clear all history
  Future<void> clearAllHistory() async {
    await _historyService.clearAllHistory();
    _history = [];
    notifyListeners();
  }

  /// Get a specific history entry by ID
  TranscriptionHistory? getHistoryById(String id) {
    try {
      return _history.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Search history by text content
  List<TranscriptionHistory> search(String query) {
    if (query.isEmpty) return history;

    final lowerQuery = query.toLowerCase();
    return _history.where((item) {
      return item.audioFileName.toLowerCase().contains(lowerQuery) ||
             item.transcription.text.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Filter history by language
  List<TranscriptionHistory> filterByLanguage(String? language) {
    if (language == null || language.isEmpty || language == 'all') {
      return history;
    }

    return _history.where((item) {
      return item.transcription.language.toLowerCase() == language.toLowerCase();
    }).toList();
  }

  /// Filter history by date range
  Future<List<TranscriptionHistory>> filterByDateRange(DateTime start, DateTime end) async {
    return await _historyService.filterByDateRange(start, end);
  }

  /// Reload history from storage
  Future<void> _reload() async {
    _history = await _historyService.getAllHistory();
    notifyListeners();
  }

  /// Force refresh history from storage
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _reload();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
