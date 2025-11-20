import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Utility class for creating consistent markdown style sheets
/// Eliminates code duplication across widgets that display markdown content
class MarkdownStyles {
  /// Creates a standard markdown style sheet based on the theme
  /// Uses bodyLarge as the base text style
  static MarkdownStyleSheet standard(BuildContext context) {
    return MarkdownStyleSheet(
      p: Theme.of(context).textTheme.bodyLarge,
      h1: Theme.of(context).textTheme.headlineSmall,
      h2: Theme.of(context).textTheme.titleLarge,
      h3: Theme.of(context).textTheme.titleMedium,
      code: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
      listBullet: Theme.of(context).textTheme.bodyLarge,
    );
  }

  /// Creates a markdown style sheet with bodyMedium as the base
  /// Useful for more compact content
  static MarkdownStyleSheet medium(BuildContext context) {
    return MarkdownStyleSheet(
      p: Theme.of(context).textTheme.bodyMedium,
      h1: Theme.of(context).textTheme.headlineSmall,
      h2: Theme.of(context).textTheme.titleLarge,
      h3: Theme.of(context).textTheme.titleMedium,
      code: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
      listBullet: Theme.of(context).textTheme.bodyMedium,
    );
  }

  /// Creates a custom markdown style sheet based on a provided text style
  /// Useful for custom styling requirements
  static MarkdownStyleSheet custom(TextStyle baseStyle) {
    final baseFontSize = baseStyle.fontSize ?? 16;
    return MarkdownStyleSheet(
      p: baseStyle,
      h1: baseStyle.copyWith(
        fontSize: baseFontSize * 1.5,
        fontWeight: FontWeight.bold,
      ),
      h2: baseStyle.copyWith(
        fontSize: baseFontSize * 1.3,
        fontWeight: FontWeight.bold,
      ),
      h3: baseStyle.copyWith(
        fontSize: baseFontSize * 1.1,
        fontWeight: FontWeight.bold,
      ),
      code: baseStyle.copyWith(
        fontFamily: 'monospace',
      ),
      listBullet: baseStyle,
    );
  }
}
