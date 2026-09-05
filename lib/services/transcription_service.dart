import '../models/transcript_segment.dart';
import '../models/transcription_options.dart';
import '../models/transcription_result.dart';
import '../repositories/model_repository.dart';
import '../utils/audio_formats.dart';
import 'completion/i_completion_service.dart';
import 'diarized_transcript_builder.dart';
import 'speaker_extraction_service.dart';
import 'transcription/i_speech_to_text_service.dart';
import 'transcription/openrouter_speech_to_text_service.dart';
import 'transcription_formatter_service.dart';

/// Interface for transcription services
abstract class ITranscriptionService {
  /// Transcribes [base64Audio]; [audioPath] names the file it came from, so
  /// the format sent to the API follows the container instead of a MIME type
  Future<TranscriptionResult> transcribe({
    required String apiKey,
    required String base64Audio,
    required String audioPath,
    required String language,
    required TranscriptionOptions options,
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
  final IDiarizedTranscriptBuilder _diarizedTranscriptBuilder;

  TranscriptionService({
    required ICompletionService completionService,
    ISpeechToTextService? speechToTextService,
    ISpeakerExtractionService? speakerExtractionService,
    ITranscriptionFormatterService? formatterService,
    IDiarizedTranscriptBuilder? diarizedTranscriptBuilder,
  })  : _completionService = completionService,
        _speechToTextService =
            speechToTextService ?? OpenRouterSpeechToTextService(),
        _speakerExtractionService =
            speakerExtractionService ?? SpeakerExtractionService(),
        _formatterService =
            formatterService ?? TranscriptionFormatterService(),
        _diarizedTranscriptBuilder =
            diarizedTranscriptBuilder ?? DiarizedTranscriptBuilder();

  @override
  Future<TranscriptionResult> transcribe({
    required String apiKey,
    required String base64Audio,
    required String audioPath,
    required String language,
    required TranscriptionOptions options,
  }) async {
    final speechToTextResult = await _speechToTextService.transcribe(
      apiKey: apiKey,
      base64Audio: base64Audio,
      format: AudioFormats.apiFormatForPath(audioPath),
      language: language,
      diarization: options.speakerDiarization,
      phrases: options.keywords,
      transcribeStyle: options.style,
    );

    final resultLanguage = speechToTextResult.detectedLanguage ?? language;

    if (options.speakerDiarization && speechToTextResult.hasSpeakerLabels) {
      return _resultFromProviderDiarization(
        speechToTextResult,
        resultLanguage,
        options.speakerLabel,
      );
    }

    if (options.style == TranscribeStyle.verbatim) {
      return _buildResult(
        text: _formatterService.formatTranscription(speechToTextResult.text),
        language: resultLanguage,
        segments: speechToTextResult.segments,
      );
    }

    final rawText = await _completionService.complete(
      apiKey: apiKey,
      messages: _buildMessages(
        speechToTextResult.text,
        language,
        options.speakerDiarization,
      ),
      config: _getConfig(),
    );

    return _buildResult(
      text: _formatterService.formatTranscription(rawText),
      language: resultLanguage,
      segments: speechToTextResult.segments,
    );
  }

  /// Builds the result from the speaker labels the model itself returned,
  /// which avoids a second LLM pass and keeps labels stable
  TranscriptionResult _resultFromProviderDiarization(
    SpeechToTextResult speechToTextResult,
    String language,
    String Function(int position) speakerLabel,
  ) {
    final diarized = _diarizedTranscriptBuilder.build(
      speechToTextResult.segments,
      speakerLabel,
    );

    return _buildResult(
      text: _formatterService.formatTranscription(diarized.text),
      language: language,
      segments: diarized.segments,
    );
  }

  TranscriptionResult _buildResult({
    required String text,
    required String language,
    required List<TranscriptSegment> segments,
  }) {
    return TranscriptionResult(
      text: text,
      language: language,
      modelUsed: _speechToTextService.model,
      timestamp: DateTime.now(),
      speakers: _speakerExtractionService.extractSpeakers(text),
      segments: segments,
    );
  }

  List<CompletionMessage> _buildMessages(
    String rawTranscript,
    String language,
    bool speakerDiarization,
  ) {
    final prompt = _getCleanupPrompt(language, speakerDiarization);

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
