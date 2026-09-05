import '../../models/transcription_history.dart';
import '../../models/transcript_segment.dart';
import 'i_export_content_formatter.dart';

/// Formatiert die Zeitmarken einer Transkription als SRT-Untertitel.
class SrtExportFormatter implements IExportContentFormatter {
  String _removeFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0) {
      return fileName.substring(0, lastDot);
    }
    return fileName;
  }

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
      buffer.writeln('${_timeCode(segment.startMs)} --> ${_timeCode(segment.endMs)}');
      buffer.writeln(text);
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }

  @override
  String getSubject(TranscriptionHistory history) {
    return _removeFileExtension(history.audioFileName);
  }

  String _timeCode(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = duration.inMilliseconds.remainder(1000).toString().padLeft(3, '0');

    return '$hours:$minutes:$seconds,$millis';
  }
}
