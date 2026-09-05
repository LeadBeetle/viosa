import '../models/model_config.dart';

/// Repository for model configuration
/// Single source of truth for all model metadata
class ModelRepository {
  /// Model used for every LLM use case (prompts, chat, speaker context,
  /// transcription post-processing)
  static const String defaultModelId = 'google/gemini-3.8-flash';

  /// Model used for speech-to-text via the OpenRouter transcription endpoint
  static const String transcriptionModelId = 'microsoft/mai-transcribe-2';

  /// Tier identifiers (used for comparison, not displayed)
  static const String tierFast = 'fast';
  static const String tierPremium = 'premium';

  /// Configuration of the speech-to-text model
  static const ModelConfig transcriptionModel = ModelConfig(
    id: transcriptionModelId,
    name: 'MAI-Transcribe 2',
    provider: 'Microsoft',
    tier: tierFast,
    description: 'fast',
    temperature: 0.0,
    capabilities: {
      'audio_transcription': true,
      'streaming': false,
      'multimodal': false,
    },
  );

  /// All supported LLM models with their configurations
  static const List<ModelConfig> supportedModels = [
    ModelConfig(
      id: defaultModelId,
      name: 'Gemini 3.8 Flash',
      provider: 'Google',
      tier: tierFast,
      description: 'fast',
      maxTokens: 10000,
      temperature: 0.3,
      capabilities: {
        'audio_transcription': false,
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
    if (id == transcriptionModelId) return transcriptionModel;
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
    return id == transcriptionModelId || supportedModels.any((m) => m.id == id);
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
