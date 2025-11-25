import 'llm_provider.dart';
import 'completion/completion_service_factory.dart';

/// Factory for creating LLM provider instances
/// @deprecated Use CompletionServiceFactory, TranscriptionService, or PromptProcessingService directly
class LLMProviderFactory {
  static const String openRouterId = CompletionServiceFactory.openRouterId;
  static const String defaultProviderId = CompletionServiceFactory.defaultProviderId;

  /// Create an LLM provider instance (backward compatible)
  /// @deprecated Use CompletionServiceFactory.create() instead
  static ILLMProvider create({
    String? providerId,
    String? model,
  }) {
    final completionService = CompletionServiceFactory.create(
      providerId: providerId,
      model: model,
    );
    return LLMProviderAdapter(completionService: completionService);
  }

  /// Create a provider for the given model
  /// @deprecated Use CompletionServiceFactory.createForModel() instead
  static ILLMProvider createForModel(String model) {
    return create(model: model);
  }

  /// Get list of supported provider IDs
  static List<String> get supportedProviders => CompletionServiceFactory.supportedProviders;

  /// Check if a provider is supported
  static bool isSupported(String providerId) {
    return CompletionServiceFactory.isSupported(providerId);
  }

  /// Get display name for a provider
  static String getProviderName(String providerId) {
    return CompletionServiceFactory.getProviderName(providerId);
  }
}
