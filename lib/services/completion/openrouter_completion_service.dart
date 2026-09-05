import 'dart:convert';
import 'package:dio/dio.dart';
import '../llm_exceptions.dart';
import '../openrouter_http.dart';
import 'i_completion_service.dart';

/// OpenRouter implementation of ICompletionService
/// Follows Single Responsibility: Only handles HTTP communication with OpenRouter API
class OpenRouterCompletionService implements ICompletionService {
  final Dio _dio;
  final String baseUrl;

  @override
  final String model;

  @override
  String get providerId => 'openrouter';

  @override
  String get providerName => 'OpenRouter';

  OpenRouterCompletionService({
    Dio? dio,
    this.baseUrl = OpenRouterHttp.baseUrl,
    required this.model,
  }) : _dio = dio ?? Dio() {
    OpenRouterHttp.configureTimeouts(_dio);
  }

  @override
  Future<String> complete({
    required String apiKey,
    required List<CompletionMessage> messages,
    CompletionConfig config = const CompletionConfig(),
  }) async {
    final request = _buildRequest(messages, config);

    try {
      final response = await _dio.post(
        '$baseUrl/chat/completions',
        data: request,
        options: Options(
          headers: OpenRouterHttp.buildHeaders(apiKey),
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      OpenRouterHttp.throwForStatus(response.statusCode, response.data);
      return _extractContent(response.data);
    } on LLMProviderException {
      rethrow;
    } on DioException catch (e) {
      throw OpenRouterHttp.mapDioException(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw LLMProviderException('Completion failed: $e');
    }
  }

  @override
  Stream<String> completeStreaming({
    required String apiKey,
    required List<CompletionMessage> messages,
    CompletionConfig config = const CompletionConfig(),
    CancelToken? cancelToken,
  }) async* {
    final request = _buildRequest(messages, config);
    request['stream'] = true;

    try {
      final response = await _dio.post<ResponseBody>(
        '$baseUrl/chat/completions',
        data: request,
        options: Options(
          headers: OpenRouterHttp.buildHeaders(apiKey),
          responseType: ResponseType.stream,
          validateStatus: (status) => status != null && status < 600,
        ),
        cancelToken: cancelToken,
      );

      _handleStreamingResponseErrors(response);
      yield* _processStream(response);
    } on LLMProviderException {
      rethrow;
    } on DioException catch (e) {
      throw OpenRouterHttp.mapDioException(e);
    } catch (e) {
      if (e is LLMProviderException) rethrow;
      throw LLMProviderException('Streaming failed: $e');
    }
  }

  Map<String, dynamic> _buildRequest(
    List<CompletionMessage> messages,
    CompletionConfig config,
  ) {
    return {
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'max_tokens': config.maxTokens,
      'temperature': config.temperature,
    };
  }

  void _handleStreamingResponseErrors(Response<ResponseBody> response) {
    if (response.statusCode == 401) throw LLMAuthException();
    if (response.statusCode == 429) throw LLMRateLimitException();
    if (response.statusCode == 503) {
      throw LLMServerException(503, 'Service temporarily unavailable.');
    }
    if (response.statusCode != null && response.statusCode! >= 500) {
      throw LLMServerException(response.statusCode!);
    }
    if (response.statusCode != 200) {
      throw LLMProviderException('API error: Status ${response.statusCode}');
    }
    if (response.data == null) {
      throw LLMProviderException('No data received from API');
    }
  }

  String _extractContent(Map<String, dynamic> responseData) {
    try {
      return responseData['choices'][0]['message']['content'] as String;
    } catch (e) {
      throw LLMProviderException('Failed to parse API response: $e');
    }
  }

  Stream<String> _processStream(Response<ResponseBody> response) async* {
    String buffer = '';

    await for (var chunk in response.data!.stream) {
      try {
        buffer += utf8.decode(chunk);

        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);

          if (line.isEmpty) continue;
          if (line == 'data: [DONE]') return;

          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6);
            try {
              final json = jsonDecode(jsonStr) as Map<String, dynamic>;
              final content = json['choices']?[0]?['delta']?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            } catch (e) {
              continue;
            }
          }
        }
      } catch (e) {
        continue;
      }
    }
  }
}
