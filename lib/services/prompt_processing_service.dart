import '../models/prompt_result.dart';
import 'completion/i_completion_service.dart';

/// Interface for prompt processing services
abstract class IPromptProcessingService {
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

/// Service for applying prompts to text
/// LLM-independent: Uses ICompletionService for actual LLM communication
class PromptProcessingService implements IPromptProcessingService {
  final ICompletionService _completionService;

  PromptProcessingService({
    required ICompletionService completionService,
  }) : _completionService = completionService;

  @override
  Future<PromptResult> applyPrompt({
    required String apiKey,
    required String promptName,
    required String promptTemplate,
    required String transcriptionText,
  }) async {
    final processedPrompt = _applyTranscriptionToTemplate(promptTemplate, transcriptionText);
    final messages = [
      CompletionMessage(role: 'user', content: processedPrompt),
    ];

    final response = await _completionService.complete(
      apiKey: apiKey,
      messages: messages,
      config: const CompletionConfig(maxTokens: 4000, temperature: 0.7),
    );

    return PromptResult(
      promptName: promptName,
      promptTemplate: promptTemplate,
      transcriptionText: transcriptionText,
      llmResponse: response,
      modelUsed: _completionService.model,
    );
  }

  @override
  Stream<String> applyPromptStreaming({
    required String apiKey,
    required String promptName,
    required String promptTemplate,
    required String transcriptionText,
  }) {
    final processedPrompt = _applyTranscriptionToTemplate(promptTemplate, transcriptionText);
    final messages = [
      CompletionMessage(role: 'user', content: processedPrompt),
    ];

    return _completionService.completeStreaming(
      apiKey: apiKey,
      messages: messages,
      config: const CompletionConfig(maxTokens: 4000, temperature: 0.7),
    );
  }

  String _applyTranscriptionToTemplate(String template, String transcription) {
    if (template.contains('{transcription}')) {
      return template.replaceAll('{transcription}', transcription);
    }
    return '$template\n\n$transcription';
  }
}
