import '../../models/transcription_history.dart';
import '../../models/transcript_segment.dart';
import '../../utils/duration_formatter.dart';
import '../../utils/path_utils.dart';
import 'i_export_content_formatter.dart';

/// Formatiert die Zeitmarken einer Transkription als SRT-Untertitel.
class SrtExportFormatter implements IExportContentFormatter {
  @override
  String format(TranscriptionHistory history) {
    final segments = history.transcription?.segments ?? const <TranscriptSegment>[];
    final buffer = StringBuffer();

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final speaker = segment.speaker;
      final text = speaker == null || speaker.isEmpty
          ? segment.text
          : '$speaker: ${segment.text}';

      buffer.writeln('${i + 1}');
      buffer.writeln(
        '${DurationFormatter.srtTimeCode(segment.startMs)} --> '
        '${DurationFormatter.srtTimeCode(segment.endMs)}',
      );
      buffer.writeln(text);
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }

  @override
  String getSubject(TranscriptionHistory history) {
    return PathUtils.removeExtension(history.audioFileName);
  }
}
