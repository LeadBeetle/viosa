import '../models/transcript_segment.dart';

/// Builds a readable transcript from the speaker labels the speech-to-text
/// model returns, so diarization no longer depends on an LLM guessing speakers
abstract class IDiarizedTranscriptBuilder {
  /// Renders [segments] as markdown with bold speaker labels
  String build(List<TranscriptSegment> segments, String language);

  /// Returns the segments with their raw provider labels replaced by the
  /// display labels used in the transcript
  List<TranscriptSegment> withDisplayLabels(
    List<TranscriptSegment> segments,
    String language,
  );
}

class DiarizedTranscriptBuilder implements IDiarizedTranscriptBuilder {
  static const String _germanSpeakerLabel = 'Sprecher';
  static const String _englishSpeakerLabel = 'Speaker';

  @override
  String build(List<TranscriptSegment> segments, String language) {
    final labelled = withDisplayLabels(segments, language);
    if (labelled.isEmpty) return '';

    final buffer = StringBuffer();
    String? currentSpeaker;

    for (final segment in labelled) {
      final text = segment.text.trim();
      if (text.isEmpty) continue;

      if (segment.speaker != currentSpeaker) {
        if (buffer.isNotEmpty) buffer.write('\n\n');
        currentSpeaker = segment.speaker;
        if (currentSpeaker != null) {
          buffer.write('**$currentSpeaker:** ');
        }
        buffer.write(text);
      } else {
        buffer.write(' ');
        buffer.write(text);
      }
    }

    return buffer.toString().trimRight();
  }

  @override
  List<TranscriptSegment> withDisplayLabels(
    List<TranscriptSegment> segments,
    String language,
  ) {
    final displayLabels = <String, String>{};
    final prefix = language.toLowerCase().startsWith('de')
        ? _germanSpeakerLabel
        : _englishSpeakerLabel;

    return segments.map((segment) {
      final raw = segment.speaker?.trim();
      if (raw == null || raw.isEmpty) return segment;

      final label = displayLabels.putIfAbsent(
        raw,
        () => _displayLabel(raw, prefix, displayLabels.length + 1),
      );

      return segment.copyWith(speaker: label);
    }).toList();
  }

  String _displayLabel(String rawLabel, String prefix, int position) {
    final containsLetters = RegExp(r'[A-Za-zÄÖÜäöüß]').hasMatch(rawLabel);
    final looksGeneric = RegExp(
      r'^(speaker|sprecher)[\s_-]*\d*$',
      caseSensitive: false,
    ).hasMatch(rawLabel);

    if (containsLetters && !looksGeneric) return rawLabel;

    return '$prefix $position';
  }
}
