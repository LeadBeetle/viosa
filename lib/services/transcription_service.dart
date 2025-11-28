import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/transcription_result.dart';
import '../repositories/model_repository.dart';
import 'completion/i_completion_service.dart';
import 'speaker_context_service.dart';
import 'speaker_extraction_service.dart';
import 'transcription_formatter_service.dart';

/// Interface for transcription services
abstract class ITranscriptionService {
  Future<TranscriptionResult> transcribe({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
    TranscriptionContext? speakerContext,
    bool speakerDiarization = false,
  });

  Stream<String> transcribeStreaming({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
    TranscriptionContext? speakerContext,
    bool speakerDiarization = false,
    CancelToken? cancelToken,
  });
}

/// Service for audio transcription
/// LLM-independent: Uses ICompletionService for actual LLM communication
class TranscriptionService implements ITranscriptionService {
  final ICompletionService _completionService;
  final ISpeakerExtractionService _speakerExtractionService;
  final ITranscriptionFormatterService _formatterService;

  TranscriptionService({
    required ICompletionService completionService,
    ISpeakerExtractionService? speakerExtractionService,
    ITranscriptionFormatterService? formatterService,
  })  : _completionService = completionService,
        _speakerExtractionService =
            speakerExtractionService ?? SpeakerExtractionService(),
        _formatterService =
            formatterService ?? TranscriptionFormatterService();

  @override
  Future<TranscriptionResult> transcribe({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
    TranscriptionContext? speakerContext,
    bool speakerDiarization = false,
  }) async {
    final messages = _buildMessages(base64Audio, mimeType, language, speakerContext, speakerDiarization);
    final config = _getConfig();

    final rawText = await _completionService.complete(
      apiKey: apiKey,
      messages: messages,
      config: config,
    );

    final formattedText = _formatterService.formatTranscription(rawText);
    final speakers = _speakerExtractionService.extractSpeakers(formattedText);

    return TranscriptionResult(
      text: formattedText,
      language: language,
      modelUsed: _completionService.model,
      timestamp: DateTime.now(),
      speakers: speakers,
    );
  }

  @override
  Stream<String> transcribeStreaming({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
    TranscriptionContext? speakerContext,
    bool speakerDiarization = false,
    CancelToken? cancelToken,
  }) {
    final messages = _buildMessages(base64Audio, mimeType, language, speakerContext, speakerDiarization);
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
    TranscriptionContext? speakerContext,
    bool speakerDiarization,
  ) {
    final basePrompt = _getTranscriptionPrompt(language, speakerDiarization);
    final contextPrompt = speakerContext?.toPromptString(language) ?? '';
    final prompt = contextPrompt.isNotEmpty
        ? '$contextPrompt\n$basePrompt'
        : basePrompt;
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

  String _getTranscriptionPrompt(String language, bool speakerDiarization) {
    final diarizationDe = speakerDiarization
        ? '''

Sprecheridentifikation:
- Identifiziere verschiedene Sprecher anhand ihrer Stimme
- Versuche, die Namen der Sprecher aus dem Gespräch zu ermitteln (z.B. wenn jemand mit Namen angesprochen wird oder sich vorstellt)
- Verwende den ermittelten Namen als Label, ansonsten "Sprecher 1:", "Sprecher 2:", etc.
- Schreibe Sprechernamen fett in Markdown-Syntax (z.B. **Max:** oder **Sprecher 1:**)
- Behalte die Sprecherzuordnung konsistent über das gesamte Transkript
- Bei nur einem Sprecher ist keine Kennzeichnung nötig
'''
        : '';

    final diarizationEn = speakerDiarization
        ? '''

Speaker identification:
- Identify different speakers by their voice
- Try to determine speaker names from the conversation (e.g. when someone is addressed by name or introduces themselves)
- Use the identified name as label, otherwise use "Speaker 1:", "Speaker 2:", etc.
- Write speaker names in bold using Markdown syntax (e.g. **John:** or **Speaker 1:**)
- Keep speaker assignments consistent throughout the transcript
- No labeling needed if there is only one speaker
'''
        : '';

    switch (language) {
      case 'de':
        return '''Transkribiere die folgende Audiodatei auf Deutsch.
$diarizationDe
Bereinige das Transkript wie folgt:
- Entferne Füllwörter (ähm, äh, hmm, also, halt, irgendwie, sozusagen, quasi, ja also)
- Entferne Wortwiederholungen und Stotterer
- Korrigiere offensichtliche Versprecher
- Wandle unvollständige Sätze in vollständige um, wenn der Kontext klar ist
- Behalte Fachbegriffe und Namen bei

Gib nur den bereinigten Text zurück, ohne zusätzliche Erklärungen.''';
      case 'en':
        return '''Transcribe the following audio file in English.
$diarizationEn
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
$diarizationEn
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
