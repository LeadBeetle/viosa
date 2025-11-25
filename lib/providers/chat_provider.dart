import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/transcription_history.dart';
import '../services/i_chat_service.dart';
import '../services/chat_service.dart';
import 'history_provider.dart';

/// Provider for managing chat state
/// Follows Single Responsibility: Only handles chat-related state
class ChatProvider with ChangeNotifier {
  final IChatService _chatService = ChatService();

  List<ChatMessage> _messages = [];
  Set<String> _enabledContexts = {'transcription'};
  bool _isStreaming = false;
  String _currentStreamedResponse = '';
  String? _error;

  // Context data
  String? _transcription;
  Map<String, String> _promptResults = {};
  String? _historyId;
  String? _recordingName;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  Set<String> get enabledContexts => Set.unmodifiable(_enabledContexts);
  bool get isStreaming => _isStreaming;
  String get currentStreamedResponse => _currentStreamedResponse;
  String? get error => _error;
  String? get historyId => _historyId;
  String? get recordingName => _recordingName;

  /// Get all available context keys
  List<String> get availableContexts {
    final contexts = <String>[];
    if (_transcription != null) {
      contexts.add('transcription');
    }
    contexts.addAll(_promptResults.keys);
    return contexts;
  }

  /// Load chat state from a TranscriptionHistory
  void loadFromHistory(TranscriptionHistory history) {
    _historyId = history.id;
    _recordingName = history.audioFileName;
    _transcription = history.transcription?.text;
    _promptResults = {
      for (final pr in history.promptResults) pr.promptName: pr.llmResponse
    };
    _messages = List.from(history.chatMessages ?? []);

    // Reset enabled contexts to default (only transcription)
    _enabledContexts = {'transcription'};

    _error = null;
    notifyListeners();
  }

  /// Toggle a context on or off
  /// Note: 'transcription' cannot be toggled off - it's always enabled
  void toggleContext(String contextKey) {
    if (contextKey == 'transcription') return;

    if (_enabledContexts.contains(contextKey)) {
      _enabledContexts.remove(contextKey);
    } else {
      _enabledContexts.add(contextKey);
    }
    notifyListeners();
  }

  /// Check if a context is enabled
  bool isContextEnabled(String contextKey) {
    return _enabledContexts.contains(contextKey);
  }

  /// Send a message and receive streaming response
  Future<void> sendMessage(
    String message, {
    required String apiKey,
    required String model,
  }) async {
    if (message.trim().isEmpty) return;

    _error = null;

    // Parse mentions from the message
    final mentions = _chatService.parseMentions(message);

    // Add user message
    final userMessage = ChatMessage(
      role: 'user',
      content: message,
      referencedContexts: mentions.toList(),
    );
    _messages.add(userMessage);
    notifyListeners();

    // Start streaming
    _isStreaming = true;
    _currentStreamedResponse = '';
    notifyListeners();

    try {
      final context = ChatContext(
        transcription: _transcription,
        promptResults: _promptResults,
        enabledContexts: _enabledContexts,
      );

      final stream = _chatService.sendMessageStreaming(
        apiKey: apiKey,
        model: model,
        userMessage: message,
        history: _messages.sublist(0, _messages.length - 1),
        context: context,
      );

      await for (final chunk in stream) {
        _currentStreamedResponse += chunk;
        notifyListeners();
      }

      // Add assistant message
      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: _currentStreamedResponse,
      );
      _messages.add(assistantMessage);
    } catch (e) {
      _error = e.toString();
      debugPrint('Chat error: $e');
    } finally {
      _isStreaming = false;
      _currentStreamedResponse = '';
      notifyListeners();
    }
  }

  /// Save chat messages to history
  Future<void> saveToHistory(HistoryProvider historyProvider) async {
    if (_historyId == null) return;

    final history = historyProvider.getHistoryById(_historyId!);
    if (history == null) return;

    final updatedHistory = history.copyWith(
      chatMessages: List.from(_messages),
    );

    await historyProvider.saveHistory(updatedHistory);
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  /// Get display name for a context key
  String getContextDisplayName(String contextKey) {
    return _chatService.getContextDisplayName(contextKey);
  }

  /// Reset the provider state
  void reset() {
    _messages = [];
    _enabledContexts = {'transcription'};
    _isStreaming = false;
    _currentStreamedResponse = '';
    _error = null;
    _transcription = null;
    _promptResults = {};
    _historyId = null;
    _recordingName = null;
    notifyListeners();
  }
}
