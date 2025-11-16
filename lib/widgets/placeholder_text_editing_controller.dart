import 'package:flutter/material.dart';

/// Custom TextEditingController that renders placeholders like {transcription}
/// as styled chips/labels within the text field
class PlaceholderTextEditingController extends TextEditingController {
  final String placeholder;
  final TextStyle? placeholderStyle;

  PlaceholderTextEditingController({
    super.text,
    this.placeholder = '{transcription}',
    this.placeholderStyle,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final String text = this.text;
    final List<TextSpan> spans = [];

    // Default style for the placeholder if none is provided
    final TextStyle defaultPlaceholderStyle = placeholderStyle ??
        TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          backgroundColor:
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          decoration: TextDecoration.none,
        );

    // Find all occurrences of the placeholder
    final RegExp placeholderRegex = RegExp(RegExp.escape(placeholder));
    final Iterable<Match> matches = placeholderRegex.allMatches(text);

    int currentPosition = 0;

    for (final Match match in matches) {
      // Add text before the placeholder
      if (match.start > currentPosition) {
        spans.add(
          TextSpan(
            text: text.substring(currentPosition, match.start),
            style: style,
          ),
        );
      }

      // Add the placeholder with special styling
      spans.add(
        TextSpan(
          text: placeholder,
          style: style?.merge(defaultPlaceholderStyle) ?? defaultPlaceholderStyle,
        ),
      );

      currentPosition = match.end;
    }

    // Add remaining text after the last placeholder
    if (currentPosition < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentPosition),
          style: style,
        ),
      );
    }

    // If no placeholders were found, return the text as-is
    if (spans.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    return TextSpan(children: spans, style: style);
  }
}
