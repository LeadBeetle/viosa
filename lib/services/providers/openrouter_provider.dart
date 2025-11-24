import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../llm_provider.dart';
import '../../models/transcription_result.dart';
import '../../models/prompt_result.dart';
import '../../repositories/model_repository.dart';

/// OpenRouter implementation of ILLMProvider
/// Combines transcription and prompt functionality in a single provider
class OpenRouterProvider implements ILLMProvider {
  final Dio _dio;
  final String baseUrl;

  @override
  final String model;

  @override
  String get providerId => 'openrouter';

  @override
  String get providerName => 'OpenRouter';

  OpenRouterProvider({
    Dio? dio,
    this.baseUrl = 'https://openrouter.ai/api/v1',
    String? model,
  })  : model = model ?? ModelRepository.defaultModelId,
        _dio = dio ?? Dio() {
    // Configure timeouts for large audio file uploads
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(minutes: 7);
    _dio.options.receiveTimeout = const Duration(minutes: 7);
  }

  // ===== TRANSCRIPTION METHODS =====

  @override
  Future<TranscriptionResult> transcribeAudio({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
  }) async {
    final prompt = _getTranscriptionPrompt(language);
    final request = _buildTranscriptionRequest(prompt, base64Audio, mimeType);

    try {
      final response = await _dio.post(
        '$baseUrl/chat/completions',
        data: request,
        options: Options(
          headers: _buildHeaders(apiKey, 'VIOSA Audio Transcription'),
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      _handleResponseErrors(response);

      final transcribedText = _extractContent(response.data);

      return TranscriptionResult(
        text: transcribedText,
        language: language,
        modelUsed: model,
        timestamp: DateTime.now(),
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

  @override
  Stream<String> transcribeAudioStreaming({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
    CancelToken? cancelToken,
  }) async* {
    final prompt = _getTranscriptionPrompt(language);
    final request = _buildTranscriptionRequest(prompt, base64Audio, mimeType);
    request['stream'] = true;

    yield* _streamRequest(
      apiKey: apiKey,
      request: request,
      title: 'VIOSA Audio Transcription',
      cancelToken: cancelToken,
    );
  }

  // ===== PROMPT METHODS =====

  @override
  Future<PromptResult> applyPrompt({
    required String apiKey,
    required String promptName,
    required String promptTemplate,
    required String transcriptionText,
  }) async {
    final processedPrompt = _applyTranscriptionToTemplate(promptTemplate, transcriptionText);
    final request = _buildPromptRequest(processedPrompt);

    try {
      final response = await _dio.post(
        '$baseUrl/chat/completions',
        data: request,
        options: Options(
          headers: _buildHeaders(apiKey, 'VIOSA Prompt Application'),
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      _handleResponseErrors(response);

      final llmResponse = _extractContent(response.data);

      return PromptResult(
        promptName: promptName,
        promptTemplate: promptTemplate,
        transcriptionText: transcriptionText,
        llmResponse: llmResponse,
        modelUsed: model,
      );
    } on LLMProviderException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw LLMProviderException('Failed to apply prompt: $e');
    }
  }

  @override
  Stream<String> applyPromptStreaming({
    required String apiKey,
    required String promptName,
    required String promptTemplate,
    required String transcriptionText,
  }) async* {
    final processedPrompt = _applyTranscriptionToTemplate(promptTemplate, transcriptionText);
    final request = _buildPromptRequest(processedPrompt);
    request['stream'] = true;

    yield* _streamRequest(
      apiKey: apiKey,
      request: request,
      title: 'VIOSA Prompt Application',
    );
  }

  // ===== PRIVATE HELPER METHODS =====

  Map<String, String> _buildHeaders(String apiKey, String title) {
    return {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://viosa-app.local',
      'X-Title': title,
    };
  }

  Map<String, dynamic> _buildTranscriptionRequest(
    String prompt,
    String base64Audio,
    String mimeType,
  ) {
    final format = _getAudioFormat(mimeType);
    final modelConfig = ModelRepository.getModelByIdOrDefault(model);

    return {
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'input_audio',
              'input_audio': {'data': base64Audio, 'format': format},
            },
          ],
        },
      ],
      'max_tokens': modelConfig.maxTokens,
      'temperature': modelConfig.temperature,
    };
  }

  Map<String, dynamic> _buildPromptRequest(String promptText) {
    return {
      'model': model,
      'messages': [
        {'role': 'user', 'content': promptText},
      ],
      'max_tokens': 4000,
      'temperature': 0.7,
    };
  }

  String _applyTranscriptionToTemplate(String template, String transcription) {
    if (template.contains('{transcription}')) {
      return template.replaceAll('{transcription}', transcription);
    }
    return '$template\n\n$transcription';
  }

  String _getAudioFormat(String mimeType) {
    if (mimeType.contains('mp3') || mimeType.contains('mpeg')) {
      return 'mp3';
    } else if (mimeType.contains('wav')) {
      return 'wav';
    }
    debugPrint('WARNING: Unsupported audio format: $mimeType. Defaulting to mp3.');
    return 'mp3';
  }

  String _getTranscriptionPrompt(String language) {
    switch (language) {
      case 'de':
        return '''Transkribiere die folgende Audiodatei auf Deutsch.

Bereinige das Transkript wie folgt:
- Entferne Füllwörter (ähm, äh, hmm, also, halt, irgendwie, sozusagen, quasi, ja also)
- Entferne Wortwiederholungen und Stotterer
- Korrigiere offensichtliche Versprecher
- Wandle unvollständige Sätze in vollständige um, wenn der Kontext klar ist
- Behalte Fachbegriffe und Namen bei

Gib nur den bereinigten Text zurück, ohne zusätzliche Erklärungen.''';
      case 'en':
        return '''Transcribe the following audio file in English.

Clean up the transcript as follows:
- Remove filler words (um, uh, like, you know, basically, actually, I mean)
- Remove word repetitions and stutters
- Correct obvious verbal slips
- Convert incomplete sentences to complete ones when context is clear
- Preserve technical terms and names

Return only the cleaned text without additional explanations.''';
      case 'auto':
      default:
        return '''Transcribe the following audio file in its original language.

Clean up the transcript as follows:
- Remove filler words and verbal hesitations
- Remove word repetitions and stutters
- Correct obvious verbal slips
- Convert incomplete sentences to complete ones when context is clear
- Preserve technical terms and names

Return only the cleaned text without additional explanations.''';
    }
  }

  void _handleResponseErrors(Response response) {
    if (response.statusCode == 401) {
      throw LLMAuthException();
    }
    if (response.statusCode == 429) {
      throw LLMRateLimitException();
    }
    if (response.statusCode == 503) {
      throw LLMServerException(503, 'Service temporarily unavailable. Please try again in a moment.');
    }
    if (response.statusCode != null && response.statusCode! >= 500) {
      throw LLMServerException(response.statusCode!);
    }
    if (response.statusCode != 200) {
      final error = response.data['error']?['message'] ?? 'Unknown error';
      throw LLMProviderException('API error: $error', statusCode: response.statusCode);
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

  String _extractContent(Map<String, dynamic> responseData) {
    try {
      return responseData['choices'][0]['message']['content'] as String;
    } catch (e) {
      throw LLMProviderException('Failed to parse API response: $e');
    }
  }

  Stream<String> _streamRequest({
    required String apiKey,
    required Map<String, dynamic> request,
    required String title,
    CancelToken? cancelToken,
  }) async* {
    Response<ResponseBody>? response;

    try {
      response = await _dio.post<ResponseBody>(
        '$baseUrl/chat/completions',
        data: request,
        options: Options(
          headers: _buildHeaders(apiKey, title),
          responseType: ResponseType.stream,
          validateStatus: (status) => status != null && status < 600,
        ),
        cancelToken: cancelToken,
      );

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
    } on LLMProviderException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is LLMProviderException) rethrow;
      throw LLMProviderException('Streaming failed: $e');
    }
  }
}
