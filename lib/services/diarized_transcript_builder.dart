import '../models/transcript_segment.dart';

/// Transcript rendered from provider side speaker labels together with the
/// segments that carry the same labels
class DiarizedTranscript {
  final String text;
  final List<TranscriptSegment> segments;

  const DiarizedTranscript({
    required this.text,
    required this.segments,
  });
}

/// Builds a readable transcript from the speaker labels the speech-to-text
/// model returns, so diarization no longer depends on an LLM guessing speakers
abstract class IDiarizedTranscriptBuilder {
  /// Renders [segments] as markdown with bold speaker labels and returns the
  /// segments carrying those labels
  /// [speakerLabel] builds the localized label of the nth speaker, so the
  /// transcript never contains untranslated text
  DiarizedTranscript build(
    List<TranscriptSegment> segments,
    String Function(int position) speakerLabel,
  );
}

class DiarizedTranscriptBuilder implements IDiarizedTranscriptBuilder {
  @override
  DiarizedTranscript build(
    List<TranscriptSegment> segments,
    String Function(int position) speakerLabel,
  ) {
    final labelled = _withDisplayLabels(segments, speakerLabel);
    return DiarizedTranscript(
      text: _render(labelled),
      segments: labelled,
    );
  }

  String _render(List<TranscriptSegment> segments) {
    if (segments.isEmpty) return '';

    final buffer = StringBuffer();
    String? currentSpeaker;

    for (final segment in segments) {
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

  List<TranscriptSegment> _withDisplayLabels(
    List<TranscriptSegment> segments,
    String Function(int position) speakerLabel,
  ) {
    final displayLabels = <String, String>{};

    return segments.map((segment) {
      final raw = segment.speaker?.trim();
      if (raw == null || raw.isEmpty) return segment;

      final label = displayLabels.putIfAbsent(
        raw,
        () => _displayLabel(raw, speakerLabel, displayLabels.length + 1),
      );

      return segment.copyWith(speaker: label);
    }).toList();
  }

  String _displayLabel(
    String rawLabel,
    String Function(int position) speakerLabel,
    int position,
  ) {
    final containsLetters = RegExp(r'[A-Za-zÄÖÜäöüß]').hasMatch(rawLabel);
    final looksGeneric = RegExp(
      r'^(speaker|sprecher)[\s_-]*\d*$',
      caseSensitive: false,
    ).hasMatch(rawLabel);

    if (containsLetters && !looksGeneric) return rawLabel;

    return speakerLabel(position);
  }
}
