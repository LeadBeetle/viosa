import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/transcription_result.dart';
import '../repositories/model_repository.dart';
import 'completion/i_completion_service.dart';

/// Interface for transcription services
abstract class ITranscriptionService {
  Future<TranscriptionResult> transcribe({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
  });

  Stream<String> transcribeStreaming({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
    CancelToken? cancelToken,
  });
}

/// Service for audio transcription
/// LLM-independent: Uses ICompletionService for actual LLM communication
class TranscriptionService implements ITranscriptionService {
  final ICompletionService _completionService;

  TranscriptionService({
    required ICompletionService completionService,
  }) : _completionService = completionService;

  @override
  Future<TranscriptionResult> transcribe({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
  }) async {
    final messages = _buildMessages(base64Audio, mimeType, language);
    final config = _getConfig();

    final text = await _completionService.complete(
      apiKey: apiKey,
      messages: messages,
      config: config,
    );

    return TranscriptionResult(
      text: text,
      language: language,
      modelUsed: _completionService.model,
      timestamp: DateTime.now(),
    );
  }

  @override
  Stream<String> transcribeStreaming({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
    CancelToken? cancelToken,
  }) {
    final messages = _buildMessages(base64Audio, mimeType, language);
    final config = _getConfig();

    return _completionService.completeStreaming(
      apiKey: apiKey,
      messages: messages,
      config: config,
      cancelToken: cancelToken,
    );
  }

  List<CompletionMessage> _buildMessages(
    String base64Audio,
    String mimeType,
    String language,
  ) {
    final prompt = _getTranscriptionPrompt(language);
    final format = _getAudioFormat(mimeType);

    return [
      CompletionMessage(
        role: 'user',
        content: [
          {'type': 'text', 'text': prompt},
          {
            'type': 'input_audio',
            'input_audio': {'data': base64Audio, 'format': format},
          },
        ],
      ),
    ];
  }

  CompletionConfig _getConfig() {
    final modelConfig = ModelRepository.getModelByIdOrDefault(_completionService.model);
    return CompletionConfig(
      maxTokens: modelConfig.maxTokens,
      temperature: modelConfig.temperature,
    );
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
}
