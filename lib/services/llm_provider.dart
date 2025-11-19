import 'package:dio/dio.dart';
import '../models/transcription_result.dart';
import '../models/prompt_result.dart';

/// Unified interface for LLM providers
/// Abstracts away the specific API implementation details
abstract class ILLMProvider {
  /// Unique identifier for this provider (e.g., 'openrouter', 'openai')
  String get providerId;

  /// Human-readable provider name
  String get providerName;

  /// The model ID being used
  String get model;

  /// Transcribe audio to text (non-streaming)
  Future<TranscriptionResult> transcribeAudio({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
  });

  /// Transcribe audio to text with streaming
  Stream<String> transcribeAudioStreaming({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
    CancelToken? cancelToken,
  });

  /// Apply a prompt to text (non-streaming)
  Future<PromptResult> applyPrompt({
    required String apiKey,
    required String promptName,
    required String promptTemplate,
    required String transcriptionText,
  });

  /// Apply a prompt to text with streaming
  Stream<String> applyPromptStreaming({
    required String apiKey,
    required String promptName,
    required String promptTemplate,
    required String transcriptionText,
  });
}

/// Exception for LLM provider errors
class LLMProviderException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  LLMProviderException(this.message, {this.code, this.statusCode});

  @override
  String toString() => message;
}

/// Authentication error (invalid API key)
class LLMAuthException extends LLMProviderException {
  LLMAuthException([super.message = 'Invalid API key'])
      : super(code: 'auth_error', statusCode: 401);
}

/// Rate limit exceeded
class LLMRateLimitException extends LLMProviderException {
  LLMRateLimitException([super.message = 'Rate limit exceeded. Please try again later.'])
      : super(code: 'rate_limit', statusCode: 429);
}

/// Network/connection error
class LLMNetworkException extends LLMProviderException {
  LLMNetworkException([super.message = 'Network error. Please check your internet connection.'])
      : super(code: 'network_error');
}

/// Timeout error
class LLMTimeoutException extends LLMProviderException {
  LLMTimeoutException([super.message = 'Request timed out. Please try again.'])
      : super(code: 'timeout');
}

/// Server error
class LLMServerException extends LLMProviderException {
  LLMServerException(int statusCode, [String? message])
      : super(
          message ?? 'Server error ($statusCode). Please try again later.',
          code: 'server_error',
          statusCode: statusCode,
        );
}
