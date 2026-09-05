import '../models/prompt_result.dart';
import 'completion/i_completion_service.dart';
import 'prompt_processing_service.dart';

export 'llm_exceptions.dart';

/// Facade that provides backward compatibility with the old ILLMProvider interface
/// Internally delegates to PromptProcessingService
/// @deprecated Use PromptProcessingService directly
abstract class ILLMProvider {
  String get providerId;
  String get providerName;
  String get model;

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
/// @deprecated Use PromptProcessingService directly
class LLMProviderAdapter implements ILLMProvider {
  final ICompletionService _completionService;
  final PromptProcessingService _promptService;

  LLMProviderAdapter({
    required ICompletionService completionService,
  })  : _completionService = completionService,
        _promptService = PromptProcessingService(completionService: completionService);

  @override
  String get providerId => _completionService.providerId;

  @override
  String get providerName => _completionService.providerName;

  @override
  String get model => _completionService.model;

  @override
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
