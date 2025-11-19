/// Enhanced model configuration with extended metadata
/// Single source of truth for model information
class ModelConfig {
  final String id;
  final String name;
  final String provider;
  final String tier;
  final String description;
  final int maxTokens;
  final double temperature;
  final List<String> supportedLanguages;
  final Map<String, dynamic> capabilities;

  const ModelConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.tier,
    required this.description,
    this.maxTokens = 10000,
    this.temperature = 0.3,
    this.supportedLanguages = const ['de', 'en', 'auto'],
    this.capabilities = const {},
  });

  /// Get display name for the model
  String get displayName => '$name ($provider)';

  /// Check if model supports a specific capability
  bool hasCapability(String capability) => capabilities[capability] == true;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider,
        'tier': tier,
        'description': description,
        'maxTokens': maxTokens,
        'temperature': temperature,
        'supportedLanguages': supportedLanguages,
        'capabilities': capabilities,
      };

  /// Create from JSON
  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: json['provider'] as String,
      tier: json['tier'] as String,
      description: json['description'] as String,
      maxTokens: json['maxTokens'] as int? ?? 10000,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.3,
      supportedLanguages: (json['supportedLanguages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['de', 'en', 'auto'],
      capabilities:
          json['capabilities'] as Map<String, dynamic>? ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelConfig &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
