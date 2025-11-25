import '../../repositories/model_repository.dart';
import 'i_completion_service.dart';
import 'openrouter_completion_service.dart';

/// Factory for creating completion service instances
/// Centralizes service creation and makes it easy to add new providers
class CompletionServiceFactory {
  static const String openRouterId = 'openrouter';
  static const String defaultProviderId = openRouterId;

  /// Create a completion service instance
  static ICompletionService create({
    String? providerId,
    String? model,
  }) {
    final effectiveProviderId = providerId ?? defaultProviderId;
    final effectiveModel = model ?? ModelRepository.defaultModelId;

    switch (effectiveProviderId) {
      case openRouterId:
        return OpenRouterCompletionService(model: effectiveModel);
      default:
        throw UnsupportedError('Provider not supported: $effectiveProviderId');
    }
  }

  /// Create a completion service for the given model
  static ICompletionService createForModel(String model) {
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
