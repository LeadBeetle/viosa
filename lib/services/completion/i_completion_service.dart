import 'package:dio/dio.dart';

/// Represents a message in a completion request
class CompletionMessage {
  final String role;
  final dynamic content;

  const CompletionMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

/// Configuration for a completion request
class CompletionConfig {
  final int maxTokens;
  final double temperature;

  const CompletionConfig({
    this.maxTokens = 4000,
    this.temperature = 0.7,
  });
}

/// Interface for LLM completion services
/// Follows Single Responsibility: Only handles LLM API communication
abstract class ICompletionService {
  /// Unique identifier for this provider (e.g., 'openrouter', 'google')
  String get providerId;

  /// Human-readable provider name
  String get providerName;

  /// The model ID being used
  String get model;

  /// Send a completion request and get the full response
  Future<String> complete({
    required String apiKey,
    required List<CompletionMessage> messages,
    CompletionConfig config = const CompletionConfig(),
  });

  /// Send a completion request with streaming response
  Stream<String> completeStreaming({
    required String apiKey,
    required List<CompletionMessage> messages,
    CompletionConfig config = const CompletionConfig(),
    CancelToken? cancelToken,
  });
}
