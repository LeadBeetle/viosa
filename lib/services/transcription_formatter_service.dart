/// Service for formatting transcription text with consistent line breaks
abstract class ITranscriptionFormatterService {
  String formatTranscription(String text);
}

class TranscriptionFormatterService implements ITranscriptionFormatterService {
  @override
  String formatTranscription(String text) {
    if (text.isEmpty) return text;

    var result = text;

    // Normalize multiple newlines to exactly two (one empty line)
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Ensure empty line before bold speaker labels (but not at start)
    result = result.replaceAllMapped(
      RegExp(r'([^\n])\n(\*\*[^*]+:\*\*)'),
      (m) => '${m.group(1)}\n\n${m.group(2)}',
    );

    // Also handle non-bold speaker labels for backwards compatibility
    result = result.replaceAllMapped(
      RegExp(r'([^\n])\n((?:Sprecher|Speaker) \d+:)'),
      (m) => '${m.group(1)}\n\n${m.group(2)}',
    );

    // Remove trailing whitespace
    return result.trimRight();
  }
}
