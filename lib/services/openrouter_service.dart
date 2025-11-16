import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/transcription_result.dart';
import '../utils/constants.dart';

/// Interface for transcription operations
/// Following Interface Segregation Principle (ISP)
abstract class ITranscriptionService {
  Future<TranscriptionResult> transcribeAudio({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
  });

  Stream<String> transcribeAudioStreaming({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
  });
}

/// Service for OpenRouter API integration
/// Single Responsibility Principle (SRP): Only handles API communication
/// Open/Closed Principle (OCP): Can be extended with different models/providers
class OpenRouterService implements ITranscriptionService {
  final Dio _dio;
  final String baseUrl;
  final String model;

  OpenRouterService({
    Dio? dio,
    this.baseUrl = 'https://openrouter.ai/api/v1',
    this.model = AppConstants.llmModel,
  }) : _dio = dio ?? Dio();

  @override
  Future<TranscriptionResult> transcribeAudio({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
  }) async {
    final prompt = _getPromptForLanguage(language);
    final request = _buildRequest(prompt, base64Audio, mimeType);

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

      final transcribedText = _extractTranscriptionText(response.data);

      return TranscriptionResult(
        text: transcribedText,
        language: language,
        modelUsed: model,
        timestamp: DateTime.now(),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timed out. Please try again.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error. Please check your internet connection.');
      }
      throw Exception('Transcription failed: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Transcription failed: $e');
    }
  }

  Map<String, dynamic> _buildRequest(
    String prompt,
    String base64Audio,
    String mimeType,
  ) {
    // Extract audio format from mimeType (e.g., 'audio/mp3' -> 'mp3')
    final format = _getAudioFormat(mimeType);

    return {
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': prompt,
            },
            {
              'type': 'input_audio',
              'input_audio': {
                'data': base64Audio,
                'format': format,
              },
            },
          ],
        },
      ],
      'max_tokens': 10000,
      'temperature': 0.3,
    };
  }

  String _getAudioFormat(String mimeType) {
    // Extract format from mimeType (e.g., 'audio/mp3' -> 'mp3', 'audio/wav' -> 'wav')
    if (mimeType.contains('mp3') || mimeType.contains('mpeg')) {
      return 'mp3';
    } else if (mimeType.contains('wav')) {
      return 'wav';
    }
    // Default to mp3 if format is unclear
    return 'mp3';
  }

  Map<String, String> _buildHeaders(String apiKey) {
    return {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://viosa-app.local',
      'X-Title': 'VIOSA Audio Transcription',
    };
  }

  String _getPromptForLanguage(String language) {
    switch (language) {
      case 'de':
        return 'Transkribiere die folgende Audiodatei auf Deutsch. Gib nur den transkribierten Text zurück, ohne zusätzliche Erklärungen.';
      case 'en':
        return 'Transcribe the following audio file in English. Return only the transcribed text without additional explanations.';
      case 'auto':
      default:
        return 'Transcribe the following audio file in its original language. Return only the transcribed text without additional explanations.';
    }
  }

  String _extractTranscriptionText(Map<String, dynamic> responseData) {
    try {
      return responseData['choices'][0]['message']['content'] as String;
    } catch (e) {
      throw Exception('Failed to parse API response: $e');
    }
  }

  @override
  Stream<String> transcribeAudioStreaming({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
  }) async* {
    final prompt = _getPromptForLanguage(language);
    final request = _buildRequest(prompt, base64Audio, mimeType);

    // Add streaming parameter
    request['stream'] = true;

    Response<ResponseBody>? response;

    try {
      response = await _dio.post<ResponseBody>(
        '$baseUrl/chat/completions',
        data: request,
        options: Options(
          headers: _buildHeaders(apiKey),
          responseType: ResponseType.stream,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401) {
        throw Exception('Ungültiger API-Key. Bitte überprüfen Sie Ihre Einstellungen.');
      }

      if (response.statusCode == 429) {
        throw Exception('API-Rate-Limit erreicht. Bitte versuchen Sie es später erneut.');
      }

      if (response.statusCode != 200) {
        throw Exception('API-Fehler: Status ${response.statusCode}');
      }

      if (response.data == null) {
        throw Exception('Keine Daten von der API erhalten');
      }

      String buffer = '';

      await for (var chunk in response.data!.stream) {
        try {
          buffer += utf8.decode(chunk);

          // Process complete lines
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
                final content =
                    json['choices']?[0]?['delta']?['content'] as String?;
                if (content != null && content.isNotEmpty) {
                  yield content;
                }
              } catch (e) {
                // Skip malformed JSON chunks
                continue;
              }
            }
          }
        } catch (e) {
          // Continue processing even if one chunk fails
          continue;
        }
      }
    } on DioException catch (e) {
      debugPrint('DioException type: ${e.type}');
      debugPrint('DioException message: ${e.message}');
      debugPrint('DioException response: ${e.response}');
      debugPrint('DioException error: ${e.error}');

      String errorMessage;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Zeitüberschreitung bei der Anfrage. Bitte versuchen Sie es erneut.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Netzwerkfehler. Bitte überprüfen Sie Ihre Internetverbindung.';
      } else if (e.response != null) {
        // Try to get error from response
        final responseData = e.response?.data;
        debugPrint('Response data: $responseData');
        errorMessage = 'API-Fehler (${e.response?.statusCode}): ${e.response?.statusMessage ?? e.message}';
      } else if (e.message != null) {
        errorMessage = 'Transkription fehlgeschlagen: ${e.message}';
      } else if (e.error != null) {
        errorMessage = 'Transkription fehlgeschlagen: ${e.error}';
      } else {
        errorMessage = 'Transkription fehlgeschlagen: Unbekannter DioException-Fehler (${e.type})';
      }
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      // Enhanced error logging
      debugPrint('Transcription streaming error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (e is Exception) rethrow;
      throw Exception('Transkription fehlgeschlagen: ${e.toString()}');
    }
  }
}
