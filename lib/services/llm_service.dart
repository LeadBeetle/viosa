import 'package:dio/dio.dart';
import '../models/prompt_result.dart';
import '../utils/constants.dart';

/// Interface for LLM operations
/// Following Interface Segregation Principle (ISP)
abstract class ILLMService {
  Future<PromptResult> applyPrompt({
    required String apiKey,
    required String promptName,
    required String promptTemplate,
    required String transcriptionText,
  });
}

/// Service for LLM interactions via OpenRouter
/// Single Responsibility Principle (SRP): Only handles LLM API calls
/// Open/Closed Principle (OCP): Can be extended for streaming support
class LLMService implements ILLMService {
  final Dio _dio;
  final String baseUrl;
  final String model;

  LLMService({
    Dio? dio,
    this.baseUrl = 'https://openrouter.ai/api/v1',
    this.model = AppConstants.llmModel,
  }) : _dio = dio ?? Dio();

  @override
  Future<PromptResult> applyPrompt({
    required String apiKey,
    required String promptName,
    required String promptTemplate,
    required String transcriptionText,
  }) async {
    final request = _buildRequest(promptTemplate);

    try {
      final response = await _dio.post(
        '$baseUrl/chat/completions',
        data: request,
        options: Options(
          headers: _buildHeaders(apiKey),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      }

      if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      }

      if (response.statusCode != 200) {
        final error = response.data['error']?['message'] ?? 'Unknown error';
        throw Exception('API error: $error');
      }

      final llmResponse = _extractResponseText(response.data);

      return PromptResult(
        promptName: promptName,
        promptTemplate: promptTemplate,
        transcriptionText: transcriptionText,
        llmResponse: llmResponse,
        modelUsed: model,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timed out. Please try again.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your internet connection.');
      }
      throw Exception('Failed to apply prompt: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to apply prompt: $e');
    }
  }

  Map<String, dynamic> _buildRequest(String promptText) {
    return {
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': promptText,
        },
      ],
      'max_tokens': 4000,
      'temperature': 0.7,
    };
  }

  Map<String, String> _buildHeaders(String apiKey) {
    return {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://viosa-app.local',
      'X-Title': 'VIOSA Prompt Application',
    };
  }

  String _extractResponseText(Map<String, dynamic> responseData) {
    try {
      return responseData['choices'][0]['message']['content'] as String;
    } catch (e) {
      throw Exception('Failed to parse API response: $e');
    }
  }
}
