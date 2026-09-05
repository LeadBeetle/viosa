import 'package:dio/dio.dart';
import '../llm_exceptions.dart';
import '../../repositories/model_repository.dart';
import 'i_speech_to_text_service.dart';

/// OpenRouter implementation of ISpeechToTextService
/// Uses the dedicated /audio/transcriptions endpoint
class OpenRouterSpeechToTextService implements ISpeechToTextService {
  final Dio _dio;
  final String baseUrl;

  @override
  final String model;

  @override
  String get providerId => 'openrouter';

  @override
  String get providerName => 'OpenRouter';

  OpenRouterSpeechToTextService({
    Dio? dio,
    this.baseUrl = 'https://openrouter.ai/api/v1',
    this.model = ModelRepository.transcriptionModelId,
  }) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(minutes: 7);
    _dio.options.receiveTimeout = const Duration(minutes: 7);
  }

  @override
  Future<SpeechToTextResult> transcribe({
    required String apiKey,
    required String base64Audio,
    required String format,
    String? language,
  }) async {
    final request = <String, dynamic>{
      'model': model,
      'input_audio': {
        'data': base64Audio,
        'format': format,
      },
    };

    if (language != null && language.isNotEmpty && language != 'auto') {
      request['language'] = language;
    }

    try {
      final response = await _dio.post(
        '$baseUrl/audio/transcriptions',
        data: request,
        options: Options(
          headers: _buildHeaders(apiKey),
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      _handleResponseErrors(response);
      return SpeechToTextResult(
        text: _extractText(response.data),
        model: model,
      );
    } on LLMProviderException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw LLMProviderException('Transcription failed: $e');
    }
  }

  Map<String, String> _buildHeaders(String apiKey) {
    return {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://viosa-app.local',
      'X-Title': 'VIOSA',
    };
  }

  void _handleResponseErrors(Response response) {
    if (response.statusCode == 401) throw LLMAuthException();
    if (response.statusCode == 429) throw LLMRateLimitException();
    if (response.statusCode == 503) {
      throw LLMServerException(503, 'Service temporarily unavailable.');
    }
    if (response.statusCode != null && response.statusCode! >= 500) {
      throw LLMServerException(response.statusCode!);
    }
    if (response.statusCode == 413) {
      throw LLMProviderException(
        'Audio payload too large for the transcription API.',
        statusCode: 413,
      );
    }
    if (response.statusCode != 200) {
      final data = response.data;
      Object? error;
      if (data is Map && data['error'] is Map) {
        error = (data['error'] as Map)['message'];
      }
      throw LLMProviderException(
        'API error: ${error ?? 'Unknown error'}',
        statusCode: response.statusCode,
      );
    }
  }

  LLMProviderException _handleDioException(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      return LLMProviderException('Request cancelled by user');
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return LLMTimeoutException('Connection timeout. Please check your internet connection.');
    }
    if (e.type == DioExceptionType.sendTimeout) {
      return LLMTimeoutException('Upload timeout. Your file may be too large or connection too slow.');
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return LLMTimeoutException('Response timeout. The server is taking too long to respond.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return LLMNetworkException();
    }
    if (e.response?.statusCode != null) {
      final statusCode = e.response!.statusCode!;
      if (statusCode == 401) return LLMAuthException();
      if (statusCode == 429) return LLMRateLimitException();
      if (statusCode >= 500) return LLMServerException(statusCode);
    }
    return LLMProviderException('Request failed: ${e.message}');
  }

  String _extractText(dynamic responseData) {
    try {
      return (responseData as Map<String, dynamic>)['text'] as String;
    } catch (e) {
      throw LLMProviderException('Failed to parse API response: $e');
    }
  }
}
