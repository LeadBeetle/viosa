import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/audio_file.dart';
import '../models/transcription_result.dart';
import '../models/prompt_result.dart';

/// Session data model for Hive storage
class SessionData {
  final AudioFile? selectedFile;
  final TranscriptionResult? transcriptionResult;
  final List<PromptResult> promptResults;
  final String? currentHistoryId;

  SessionData({
    this.selectedFile,
    this.transcriptionResult,
    List<PromptResult>? promptResults,
    this.currentHistoryId,
  }) : promptResults = promptResults ?? [];

  Map<String, dynamic> toJson() {
    return {
      'selectedFile': selectedFile?.toJson(),
      'transcriptionResult': transcriptionResult?.toJson(),
      'promptResults': promptResults.map((pr) => pr.toJson()).toList(),
      'currentHistoryId': currentHistoryId,
    };
  }

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      selectedFile: json['selectedFile'] != null
          ? AudioFile.fromJson(json['selectedFile'])
          : null,
      transcriptionResult: json['transcriptionResult'] != null
          ? TranscriptionResult.fromJson(json['transcriptionResult'])
          : null,
      promptResults: json['promptResults'] != null
          ? (json['promptResults'] as List)
              .map((pr) => PromptResult.fromJson(pr))
              .toList()
          : [],
      currentHistoryId: json['currentHistoryId'],
    );
  }
}

/// Provider for persisting HomeScreen session state
/// Allows users to resume their work when reopening the app
class SessionStateProvider with ChangeNotifier {
  static const String _sessionBoxName = 'home_screen_session';
  static const String _sessionDataKey = 'session_data';

  Box? _sessionBox;
  bool _hasInitialized = false;

  AudioFile? _selectedFile;
  TranscriptionResult? _transcriptionResult;
  List<PromptResult> _promptResults = [];
  String? _currentHistoryId;
  bool _isInitialized = false;

  // Getters
  AudioFile? get selectedFile => _selectedFile;
  TranscriptionResult? get transcriptionResult => _transcriptionResult;
  List<PromptResult> get promptResults => List.unmodifiable(_promptResults);
  String? get currentHistoryId => _currentHistoryId;
  bool get isInitialized => _isInitialized;
  bool get hasSession => _selectedFile != null || _transcriptionResult != null;

  /// Initialize and restore session from storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Open the Hive box
      _sessionBox = await Hive.openBox(_sessionBoxName);

      // Restore session data from Hive
      final sessionData = _sessionBox!.get(_sessionDataKey);
      if (sessionData != null) {
        final Map<String, dynamic> data = _convertToStringMap(sessionData);
        final session = SessionData.fromJson(data);

        _selectedFile = session.selectedFile;
        _transcriptionResult = session.transcriptionResult;
        _promptResults = session.promptResults;
        _currentHistoryId = session.currentHistoryId;
      }

      _isInitialized = true;
      _hasInitialized = true;
    } catch (e) {
      debugPrint('Error restoring session: $e');
      // Don't throw - just start with empty session
      _isInitialized = true;
      _hasInitialized = true;
    }

    notifyListeners();
  }

  /// Update selected file and persist session
  Future<void> setSelectedFile(AudioFile? file) async {
    _selectedFile = file;
    notifyListeners();
    await _persistSession();
  }

  /// Update transcription result and persist session
  Future<void> setTranscriptionResult(TranscriptionResult? result) async {
    _transcriptionResult = result;
    notifyListeners();
    await _persistSession();
  }

  /// Update prompt results and persist session
  Future<void> setPromptResults(List<PromptResult> results) async {
    _promptResults = results;
    notifyListeners();
    await _persistSession();
  }

  /// Add a prompt result and persist session
  Future<void> addPromptResult(PromptResult result) async {
    _promptResults.add(result);
    notifyListeners();
    await _persistSession();
  }

  /// Update current history ID and persist session
  Future<void> setCurrentHistoryId(String? id) async {
    _currentHistoryId = id;
    notifyListeners();
    await _persistSession();
  }

  /// Clear all prompt results and persist session
  Future<void> clearPromptResults() async {
    _promptResults.clear();
    notifyListeners();
    await _persistSession();
  }

  /// Clear entire session
  Future<void> clearSession() async {
    _selectedFile = null;
    _transcriptionResult = null;
    _promptResults = [];
    _currentHistoryId = null;
    notifyListeners();

    if (_sessionBox != null) {
      await _sessionBox!.delete(_sessionDataKey);
    }
  }

  /// Converts a dynamic map to a properly typed Map with String keys.
  /// Recursively handles nested maps and lists.
  Map<String, dynamic> _convertToStringMap(dynamic input) {
    if (input is Map) {
      return Map<String, dynamic>.fromEntries(
        input.entries.map((entry) {
          final key = entry.key.toString();
          final value = entry.value;

          if (value is Map) {
            return MapEntry(key, _convertToStringMap(value));
          } else if (value is List) {
            return MapEntry(key, value.map((item) {
              if (item is Map) {
                return _convertToStringMap(item);
              }
              return item;
            }).toList());
          }
          return MapEntry(key, value);
        }),
      );
    }
    return {};
  }

  /// Persist current session state to storage
  Future<void> _persistSession() async {
    if (!_hasInitialized || _sessionBox == null) {
      return; // Skip if not initialized yet
    }

    try {
      final sessionData = SessionData(
        selectedFile: _selectedFile,
        transcriptionResult: _transcriptionResult,
        promptResults: _promptResults,
        currentHistoryId: _currentHistoryId,
      );

      await _sessionBox!.put(_sessionDataKey, sessionData.toJson());
    } catch (e) {
      debugPrint('Error persisting session: $e');
      // Don't throw - session persistence is not critical
    }
  }

  /// Update complete session state at once
  Future<void> updateSession({
    AudioFile? selectedFile,
    TranscriptionResult? transcriptionResult,
    List<PromptResult>? promptResults,
    String? currentHistoryId,
  }) async {
    bool hasChanges = false;

    if (selectedFile != _selectedFile) {
      _selectedFile = selectedFile;
      hasChanges = true;
    }

    if (transcriptionResult != _transcriptionResult) {
      _transcriptionResult = transcriptionResult;
      hasChanges = true;
    }

    if (promptResults != null && promptResults != _promptResults) {
      _promptResults = promptResults;
      hasChanges = true;
    }

    if (currentHistoryId != _currentHistoryId) {
      _currentHistoryId = currentHistoryId;
      hasChanges = true;
    }

    if (hasChanges) {
      notifyListeners();
      await _persistSession();
    }
  }
}
