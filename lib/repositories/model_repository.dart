import '../models/model_config.dart';

/// Repository for model configuration
/// Single source of truth for all model metadata
class ModelRepository {
  static const String defaultModelId = 'google/gemini-2.5-flash';

  /// Tier identifiers (used for comparison, not displayed)
  static const String tierFast = 'fast';
  static const String tierPremium = 'premium';

  /// All supported models with their configurations
  static const List<ModelConfig> supportedModels = [
    ModelConfig(
      id: 'google/gemini-2.5-flash',
      name: 'Gemini 2.5 Flash',
      provider: 'Google',
      tier: tierFast,
      description: 'fast',
      maxTokens: 10000,
      temperature: 0.3,
      capabilities: {
        'audio_transcription': true,
        'streaming': true,
        'multimodal': true,
      },
    ),
    ModelConfig(
      id: 'google/gemini-2.5-pro',
      name: 'Gemini 2.5 Pro',
      provider: 'Google',
      tier: tierPremium,
      description: 'premium',
      maxTokens: 10000,
      temperature: 0.3,
      capabilities: {
        'audio_transcription': true,
        'streaming': true,
        'multimodal': true,
      },
    ),
  ];

  /// Get the default model configuration
  static ModelConfig get defaultModel {
    return supportedModels.firstWhere(
      (m) => m.id == defaultModelId,
      orElse: () => supportedModels.first,
    );
  }

  /// Get model by ID
  static ModelConfig? getModelById(String id) {
    try {
      return supportedModels.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get model by ID or return default
  static ModelConfig getModelByIdOrDefault(String id) {
    return getModelById(id) ?? defaultModel;
  }

  /// Check if a model ID is valid
  static bool isValidModel(String id) {
    return supportedModels.any((m) => m.id == id);
  }

  /// Get all model IDs
  static List<String> get allModelIds {
    return supportedModels.map((m) => m.id).toList();
  }

  /// Get models by provider
  static List<ModelConfig> getModelsByProvider(String provider) {
    return supportedModels.where((m) => m.provider == provider).toList();
  }

  /// Get models by tier
  static List<ModelConfig> getModelsByTier(String tier) {
    return supportedModels.where((m) => m.tier == tier).toList();
  }
}
