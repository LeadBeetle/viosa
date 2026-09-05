import 'dart:async';

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
  Object? _error;
  StreamSubscription<String>? _streamSubscription;
  Completer<void>? _streamCompleter;
  bool _stopRequested = false;

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
  Object? get error => _error;
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

    // Enable all available contexts by default
    _enabledContexts = {};
    if (_transcription != null) {
      _enabledContexts.add('transcription');
    }
    _enabledContexts.addAll(_promptResults.keys);

    _error = null;
    notifyListeners();
  }

  /// Toggle a context on or off
  void toggleContext(String contextKey) {
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

      await _consumeStream(stream);

      if (_currentStreamedResponse.isNotEmpty) {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: _currentStreamedResponse,
        ));
      }
    } catch (e) {
      _error = e;
      debugPrint('Chat error: $e');
    } finally {
      _streamSubscription = null;
      _streamCompleter = null;
      _stopRequested = false;
      _isStreaming = false;
      _currentStreamedResponse = '';
      notifyListeners();
    }
  }

  /// Consumes a response stream, keeping the subscription cancellable
  Future<void> _consumeStream(Stream<String> stream) {
    final completer = Completer<void>();
    _streamCompleter = completer;

    _streamSubscription = stream.listen(
      (chunk) {
        _currentStreamedResponse += chunk;
        notifyListeners();
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      onError: (Object e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  /// Stops the running response and keeps what was streamed so far
  Future<void> stopStreaming() async {
    if (!_isStreaming || _stopRequested) return;

    _stopRequested = true;
    final subscription = _streamSubscription;
    _streamSubscription = null;
    await subscription?.cancel();

    final completer = _streamCompleter;
    _streamCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
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

  /// Regenerate the response for a specific assistant message
  Future<void> regenerateResponse(
    int messageIndex, {
    required String apiKey,
    required String model,
  }) async {
    if (messageIndex < 0 || messageIndex >= _messages.length) return;
    if (_messages[messageIndex].role != 'assistant') return;
    if (_isStreaming) return;

    _error = null;

    final userMessageIndex = messageIndex - 1;
    if (userMessageIndex < 0 || _messages[userMessageIndex].role != 'user') {
      return;
    }

    final userMessage = _messages[userMessageIndex];

    _messages.removeAt(messageIndex);
    notifyListeners();

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
        userMessage: userMessage.content,
        history: _messages.sublist(0, userMessageIndex),
        context: context,
      );

      await _consumeStream(stream);

      if (_currentStreamedResponse.isNotEmpty) {
        _messages.insert(
          userMessageIndex + 1,
          ChatMessage(role: 'assistant', content: _currentStreamedResponse),
        );
      }
    } catch (e) {
      _error = e;
      debugPrint('Chat regenerate error: $e');
    } finally {
      _streamSubscription = null;
      _streamCompleter = null;
      _stopRequested = false;
      _isStreaming = false;
      _currentStreamedResponse = '';
      notifyListeners();
    }
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

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _streamCompleter = null;
    super.dispose();
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
