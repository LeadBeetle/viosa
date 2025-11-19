import 'llm_provider.dart';
import 'providers/openrouter_provider.dart';
import '../repositories/model_repository.dart';

/// Factory for creating LLM provider instances
/// Centralizes provider creation and makes it easy to add new providers
class LLMProviderFactory {
  /// Supported provider IDs
  static const String openRouterId = 'openrouter';

  /// Default provider ID
  static const String defaultProviderId = openRouterId;

  /// Create an LLM provider instance
  ///
  /// [providerId] - The provider to use (e.g., 'openrouter')
  /// [model] - The model ID to use (e.g., 'google/gemini-2.5-flash')
  ///
  /// Throws [UnsupportedError] if the provider is not supported
  static ILLMProvider create({
    String? providerId,
    String? model,
  }) {
    final effectiveProviderId = providerId ?? defaultProviderId;
    final effectiveModel = model ?? ModelRepository.defaultModelId;

    switch (effectiveProviderId) {
      case openRouterId:
        return OpenRouterProvider(model: effectiveModel);
      default:
        throw UnsupportedError('Provider not supported: $effectiveProviderId');
    }
  }

  /// Create a provider for the given model
  /// Automatically determines the correct provider based on the model
  static ILLMProvider createForModel(String model) {
    // Currently all models use OpenRouter
    // In the future, we can add logic to determine provider from model ID
    return create(model: model);
  }

  /// Get list of supported provider IDs
  static List<String> get supportedProviders => [openRouterId];

  /// Check if a provider is supported
  static bool isSupported(String providerId) {
    return supportedProviders.contains(providerId);
  }

  /// Get display name for a provider
  static String getProviderName(String providerId) {
    switch (providerId) {
      case openRouterId:
        return 'OpenRouter';
      default:
        return providerId;
    }
  }
}
