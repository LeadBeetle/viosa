import '../repositories/model_repository.dart';
import '../models/model_config.dart';

class AppConstants {
  // App Info
  static const String appName = 'Viosa';
  static const String appTitle = 'Viosa Audio Transcription';

  // API
  static const String openRouterApiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // Model configuration - delegate to ModelRepository for single source of truth
  static String get defaultModel => ModelRepository.defaultModelId;
  static List<ModelConfig> get supportedModels => ModelRepository.supportedModels;

  // Supported Languages
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'auto', name: 'Auto-Detect'),
    LanguageOption(code: 'de', name: 'Deutsch'),
    LanguageOption(code: 'en', name: 'English'),
  ];

  // File Size Limits
  static const int maxFileSizeBytes = 25 * 1024 * 1024; // 25MB

  // Legacy UI Constants (use AppSpacing, AppRadius, AppElevation instead)
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;
}

/// Spacing constants for consistent layout
class AppSpacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Opacity values for consistent visual hierarchy
class AppOpacity {
  static const double disabled = 0.38;
  static const double secondary = 0.60;
  static const double tertiary = 0.40;
  static const double scrim = 0.32;
}

/// Icon sizes for consistent iconography
class AppIconSize {
  static const double small = 16.0;
  static const double medium = 20.0;
  static const double large = 28.0;
  static const double xlarge = 32.0;
  static const double xxlarge = 48.0;
  static const double emptyState = 64.0;
  static const double logo = 120.0;
}

/// Elevation system for consistent z-index hierarchy
class AppElevation {
  static const double none = 0.0;
  static const double low = 1.0;
  static const double medium = 2.0;
  static const double high = 4.0;
  static const double modal = 8.0;
}

/// Border radius system following Material Design 3
class AppRadius {
  static const double xs = 4.0;
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xl = 28.0;
  static const double circular = 100.0;
}

/// Scroll behavior constants
class AppScrollThresholds {
  static const double scrollToTopButton = 800.0;
  static const double maxCardHeight = 600.0;
  static const double maxListHeight = 400.0;
}

/// Animation duration constants for consistent motion
class AppDuration {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

/// Loading indicator sizes for consistent feedback
class AppLoadingSize {
  static const double small = 16.0;
  static const double medium = 24.0;
  static const double large = 32.0;
}

/// Stroke width for loading indicators
class AppStrokeWidth {
  static const double thin = 2.0;
  static const double normal = 3.0;
  static const double thick = 4.0;
}

class LanguageOption {
  final String code;
  final String name;

  const LanguageOption({
    required this.code,
    required this.name,
  });
}
