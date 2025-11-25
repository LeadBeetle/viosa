import 'package:dio/dio.dart';
import '../models/transcription_result.dart';
import '../models/prompt_result.dart';
import 'completion/i_completion_service.dart';
import 'transcription_service.dart';
import 'prompt_processing_service.dart';

export 'llm_exceptions.dart';

/// Facade that provides backward compatibility with the old ILLMProvider interface
/// Internally delegates to TranscriptionService and PromptProcessingService
/// @deprecated Use TranscriptionService and PromptProcessingService directly
abstract class ILLMProvider {
  String get providerId;
  String get providerName;
  String get model;

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
    CancelToken? cancelToken,
  });

  Future<PromptResult> applyPrompt({
    required String apiKey,
    required String promptName,
    required String promptTemplate,
    required String transcriptionText,
  });

  Stream<String> applyPromptStreaming({
    required String apiKey,
    required String promptName,
    required String promptTemplate,
    required String transcriptionText,
  });
}

/// Adapter that implements ILLMProvider using the new service architecture
/// @deprecated Use TranscriptionService and PromptProcessingService directly
class LLMProviderAdapter implements ILLMProvider {
  final ICompletionService _completionService;
  final TranscriptionService _transcriptionService;
  final PromptProcessingService _promptService;

  LLMProviderAdapter({
    required ICompletionService completionService,
  })  : _completionService = completionService,
        _transcriptionService = TranscriptionService(completionService: completionService),
        _promptService = PromptProcessingService(completionService: completionService);

  @override
  String get providerId => _completionService.providerId;

  @override
  String get providerName => _completionService.providerName;

  @override
  String get model => _completionService.model;

  @override
  Future<TranscriptionResult> transcribeAudio({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
  }) {
    return _transcriptionService.transcribe(
      apiKey: apiKey,
      base64Audio: base64Audio,
      mimeType: mimeType,
      language: language,
    );
  }

  @override
  Stream<String> transcribeAudioStreaming({
    required String apiKey,
    required String base64Audio,
    required String mimeType,
    required String language,
    CancelToken? cancelToken,
  }) {
    return _transcriptionService.transcribeStreaming(
      apiKey: apiKey,
      base64Audio: base64Audio,
      mimeType: mimeType,
      language: language,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<PromptResult> applyPrompt({
    required String apiKey,
    required String promptName,
    required String promptTemplate,
    required String transcriptionText,
  }) {
    return _promptService.applyPrompt(
      apiKey: apiKey,
      promptName: promptName,
      promptTemplate: promptTemplate,
      transcriptionText: transcriptionText,
    );
  }

  @override
  Stream<String> applyPromptStreaming({
    required String apiKey,
    required String promptName,
    required String promptTemplate,
    required String transcriptionText,
  }) {
    return _promptService.applyPromptStreaming(
      apiKey: apiKey,
      promptName: promptName,
      promptTemplate: promptTemplate,
      transcriptionText: transcriptionText,
    );
  }
}
