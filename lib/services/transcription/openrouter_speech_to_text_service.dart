import 'package:dio/dio.dart';
import '../llm_exceptions.dart';
import '../openrouter_http.dart';
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
    this.baseUrl = OpenRouterHttp.baseUrl,
    this.model = ModelRepository.transcriptionModelId,
  }) : _dio = dio ?? Dio() {
    OpenRouterHttp.configureTimeouts(_dio);
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
        '$baseUrl${OpenRouterHttp.transcriptionsPath}',
        data: request,
        options: Options(
          headers: OpenRouterHttp.buildHeaders(apiKey),
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      OpenRouterHttp.throwForStatus(response.statusCode, response.data);
      return SpeechToTextResult(
        text: _extractText(response.data),
        model: model,
      );
    } on LLMProviderException {
      rethrow;
    } on DioException catch (e) {
      throw OpenRouterHttp.mapDioException(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw LLMProviderException('Transcription failed: $e');
    }
  }

  String _extractText(dynamic responseData) {
    try {
      return (responseData as Map<String, dynamic>)['text'] as String;
    } catch (e) {
      throw LLMProviderException('Failed to parse API response: $e');
    }
  }
}
