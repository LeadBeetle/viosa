import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/transcription_result.dart';
import '../repositories/model_repository.dart';
import 'completion/i_completion_service.dart';
import 'speaker_context_service.dart';
import 'speaker_extraction_service.dart';
import 'transcription/i_speech_to_text_service.dart';
import 'transcription/openrouter_speech_to_text_service.dart';
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
/// Uses ISpeechToTextService for the raw transcript and ICompletionService
/// for LLM based clean-up and speaker diarization
class TranscriptionService implements ITranscriptionService {
  final ICompletionService _completionService;
  final ISpeechToTextService _speechToTextService;
  final ISpeakerExtractionService _speakerExtractionService;
  final ITranscriptionFormatterService _formatterService;

  TranscriptionService({
    required ICompletionService completionService,
    ISpeechToTextService? speechToTextService,
    ISpeakerExtractionService? speakerExtractionService,
    ITranscriptionFormatterService? formatterService,
  })  : _completionService = completionService,
        _speechToTextService =
            speechToTextService ?? OpenRouterSpeechToTextService(),
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
    final rawTranscript = await _speechToText(
      apiKey: apiKey,
      base64Audio: base64Audio,
      mimeType: mimeType,
      language: language,
    );

    final rawText = await _completionService.complete(
      apiKey: apiKey,
      messages: _buildMessages(
        rawTranscript,
        language,
        speakerContext,
        speakerDiarization,
      ),
      config: _getConfig(),
    );

    final formattedText = _formatterService.formatTranscription(rawText);
    final speakers = _speakerExtractionService.extractSpeakers(formattedText);

    return TranscriptionResult(
      text: formattedText,
      language: language,
      modelUsed: _speechToTextService.model,
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
  }) async* {
    final rawTranscript = await _speechToText(
      apiKey: apiKey,
      base64Audio: base64Audio,
      mimeType: mimeType,
      language: language,
    );

    yield* _completionService.completeStreaming(
      apiKey: apiKey,
      messages: _buildMessages(
        rawTranscript,
        language,
        speakerContext,
        speakerDiarization,
      ),
      config: _getConfig(),
      cancelToken: cancelToken,
    );
  }

  Future<String> _speechToText({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
  }) async {
    final result = await _speechToTextService.transcribe(
      apiKey: apiKey,
      base64Audio: base64Audio,
      format: _getAudioFormat(mimeType),
      language: language,
    );
    return result.text;
  }

  List<CompletionMessage> _buildMessages(
    String rawTranscript,
    String language,
    TranscriptionContext? speakerContext,
    bool speakerDiarization,
  ) {
    final basePrompt = _getCleanupPrompt(language, speakerDiarization);
    final contextPrompt = speakerContext?.toPromptString(language) ?? '';
    final prompt = contextPrompt.isNotEmpty
        ? '$contextPrompt\n$basePrompt'
        : basePrompt;

    return [
      CompletionMessage(
        role: 'user',
        content: '$prompt\n\n---\n$rawTranscript',
      ),
    ];
  }

  CompletionConfig _getConfig() {
    final modelConfig =
        ModelRepository.getModelByIdOrDefault(_completionService.model);
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
    } else if (mimeType.contains('m4a')) {
      return 'm4a';
    } else if (mimeType.contains('mp4')) {
      return 'mp4';
    }
    debugPrint('WARNING: Unsupported audio format: $mimeType. Defaulting to mp3.');
    return 'mp3';
  }

  String _getCleanupPrompt(String language, bool speakerDiarization) {
    final diarizationDe = speakerDiarization
        ? '''

Sprecheridentifikation:
- Erkenne anhand des Gesprächsverlaufs verschiedene Sprecher
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
- Identify different speakers from the flow of the conversation
- Try to determine speaker names from the conversation (e.g. when someone is addressed by name or introduces themselves)
- Use the identified name as label, otherwise use "Speaker 1:", "Speaker 2:", etc.
- Write speaker names in bold using Markdown syntax (e.g. **John:** or **Speaker 1:**)
- Keep speaker assignments consistent throughout the transcript
- No labeling needed if there is only one speaker
'''
        : '';

    switch (language) {
      case 'de':
        return '''Das folgende Transkript stammt aus einer automatischen Spracherkennung.
$diarizationDe
Bereinige das Transkript wie folgt:
- Entferne Füllwörter (ähm, äh, hmm, also, halt, irgendwie, sozusagen, quasi, ja also)
- Entferne Wortwiederholungen und Stotterer
- Korrigiere offensichtliche Versprecher und Erkennungsfehler
- Wandle unvollständige Sätze in vollständige um, wenn der Kontext klar ist
- Behalte Fachbegriffe und Namen bei
- Erfinde keine Inhalte, die nicht im Transkript stehen

Gib nur den bereinigten Text zurück, ohne zusätzliche Erklärungen.''';
      case 'en':
        return '''The following transcript comes from automatic speech recognition.
$diarizationEn
Clean up the transcript as follows:
- Remove filler words (um, uh, like, you know, basically, actually, I mean)
- Remove word repetitions and stutters
- Correct obvious verbal slips and recognition errors
- Convert incomplete sentences to complete ones when context is clear
- Preserve technical terms and names
- Do not invent content that is not in the transcript

Return only the cleaned text without additional explanations.''';
      case 'auto':
      default:
        return '''The following transcript comes from automatic speech recognition.
Keep the original language of the transcript.
$diarizationEn
Clean up the transcript as follows:
- Remove filler words and verbal hesitations
- Remove word repetitions and stutters
- Correct obvious verbal slips and recognition errors
- Convert incomplete sentences to complete ones when context is clear
- Preserve technical terms and names
- Do not invent content that is not in the transcript

Return only the cleaned text without additional explanations.''';
    }
  }
}
