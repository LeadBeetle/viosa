import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import '../models/transcription_history.dart';

/// Interface for history service
/// Follows Interface Segregation Principle: Only history-related methods
abstract class IHistoryService {
  Future<void> initialize();
  Future<List<TranscriptionHistory>> getAllHistory();
  Future<void> saveHistory(TranscriptionHistory history);
  Future<void> deleteHistory(String id);
  Future<void> renameRecording(String id, String newName);
  Future<void> clearAllHistory();
  Future<List<TranscriptionHistory>> searchHistory(String query);
  Future<List<TranscriptionHistory>> filterByLanguage(String languageCode);
  Future<List<TranscriptionHistory>> filterByDateRange(DateTime start, DateTime end);
}

/// Service for managing transcription history
/// Follows Single Responsibility Principle: Only handles history persistence
class HistoryService implements IHistoryService {
  static const String _historyBoxName = 'transcription_history';

  Box<TranscriptionHistory>? _historyBox;
  bool _isInitialized = false;

  /// Initialize the Hive box
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Open the Hive box
    _historyBox = await Hive.openBox<TranscriptionHistory>(_historyBoxName);

    _isInitialized = true;
  }

  void _ensureInitialized() {
    if (!_isInitialized || _historyBox == null) {
      throw StateError('HistoryService not initialized. Call initialize() first.');
    }
  }

  @override
  Future<List<TranscriptionHistory>> getAllHistory() async {
    _ensureInitialized();

    try {
      final histories = _historyBox!.values.toList();
      // Sort by newest first
      histories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return histories;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveHistory(TranscriptionHistory history) async {
    _ensureInitialized();

    // Hive uses the ID as the key, so put will update if exists or add if new
    await _historyBox!.put(history.id, history);
  }

  @override
  Future<void> deleteHistory(String id) async {
    _ensureInitialized();

    await _historyBox!.delete(id);
  }

  @override
  Future<void> renameRecording(String id, String newName) async {
    _ensureInitialized();

    final history = _historyBox!.get(id);
    if (history == null) {
      throw Exception('History with id $id not found');
    }

    final extension = path.extension(history.audioFileName);
    final newFileNameWithExtension = newName.contains('.') ? newName : '$newName$extension';

    String? newAudioPath;
    if (history.audioPath != null) {
      final oldFile = File(history.audioPath!);
      if (await oldFile.exists()) {
        final directory = path.dirname(history.audioPath!);
        final sanitizedName = newFileNameWithExtension.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        newAudioPath = path.join(directory, sanitizedName);

        await oldFile.rename(newAudioPath);
      }
    }

    final updatedHistory = history.copyWith(
      audioFileName: newFileNameWithExtension,
      audioPath: newAudioPath ?? history.audioPath,
    );
    await _historyBox!.put(id, updatedHistory);
  }

  @override
  Future<void> clearAllHistory() async {
    _ensureInitialized();

    await _historyBox!.clear();
  }

  @override
  Future<List<TranscriptionHistory>> searchHistory(String query) async {
    final List<TranscriptionHistory> allHistory = await getAllHistory();

    if (query.isEmpty) {
      return allHistory;
    }

    final String lowerQuery = query.toLowerCase();
    return allHistory.where((history) {
      final bool matchesFileName = history.audioFileName.toLowerCase().contains(lowerQuery);
      final bool matchesTranscription = history.transcription?.text.toLowerCase().contains(lowerQuery) ?? false;
      final bool matchesPromptResults = history.promptResults.any(
        (pr) => pr.llmResponse.toLowerCase().contains(lowerQuery) ||
               pr.promptName.toLowerCase().contains(lowerQuery),
      );

      return matchesFileName || matchesTranscription || matchesPromptResults;
    }).toList();
  }

  @override
  Future<List<TranscriptionHistory>> filterByLanguage(String languageCode) async {
    final List<TranscriptionHistory> allHistory = await getAllHistory();

    if (languageCode == 'all') {
      return allHistory;
    }

    return allHistory.where((history) {
      return history.transcription?.language == languageCode;
    }).toList();
  }

  @override
  Future<List<TranscriptionHistory>> filterByDateRange(DateTime start, DateTime end) async {
    final List<TranscriptionHistory> allHistory = await getAllHistory();

    return allHistory.where((history) {
      final date = history.createdAt;
      return date.isAfter(start.subtract(const Duration(days: 1))) &&
             date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
}
