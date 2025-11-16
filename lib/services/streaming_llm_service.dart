import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../utils/constants.dart';

/// Interface for streaming LLM service
/// Follows Interface Segregation Principle: Only streaming-related methods
abstract class IStreamingLLMService {
  Stream<String> applyPromptStreaming({
    required String apiKey,
    required String promptName,
    required String promptTemplate,
    required String transcriptionText,
  });
}

/// Service for applying prompts with streaming responses
/// Follows Single Responsibility Principle: Only handles LLM streaming
class StreamingLLMService implements IStreamingLLMService {
  final Dio _dio = Dio();

  @override
  Stream<String> applyPromptStreaming({
    required String apiKey,
    required String promptName,
    required String promptTemplate,
    required String transcriptionText,
  }) async* {
    try {
      final response = await _dio.post(
        AppConstants.openRouterApiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://github.com/viosa-app',
            'X-Title': 'VIOSA',
          },
          responseType: ResponseType.stream,
        ),
        data: {
          'model': AppConstants.llmModel,
          'messages': [
            {
              'role': 'user',
              'content': promptTemplate,
            }
          ],
          'stream': true,
        },
      );

      final stream = response.data.stream as Stream<List<int>>;

      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        final lines = text.split('\n');

        for (final line in lines) {
          if (line.isEmpty || !line.startsWith('data: ')) {
            continue;
          }

          final data = line.substring(6); // Remove "data: " prefix

          if (data == '[DONE]') {
            break;
          }

          try {
            final json = jsonDecode(data);
            final delta = json['choices']?[0]?['delta'];
            final content = delta?['content'];

            if (content != null && content is String && content.isNotEmpty) {
              yield content;
            }
          } catch (e) {
            // Skip malformed JSON chunks
            continue;
          }
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Ungültiger API-Key');
      } else if (e.response?.statusCode == 429) {
        throw Exception('API-Rate-Limit erreicht. Bitte versuchen Sie es später erneut.');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Zeitüberschreitung. Bitte überprüfen Sie Ihre Internetverbindung.');
      } else {
        throw Exception('Fehler bei der API-Anfrage: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unerwarteter Fehler: $e');
    }
  }
}
