import '../../models/transcription_history.dart';
import '../../utils/path_utils.dart';
import 'i_export_content_formatter.dart';

/// Formatiert Transkriptionsdaten als Plain Text.
/// Strukturierte Ausgabe mit Überschriften und Abschnitten.
class PlainTextExportFormatter implements IExportContentFormatter {
  @override
  String format(TranscriptionHistory history) {
    final buffer = StringBuffer();
    final name = PathUtils.removeExtension(history.audioFileName);

    buffer.writeln('# $name');
    buffer.writeln();

    if (history.transcription != null) {
      buffer.writeln('## Transkription');
      buffer.writeln();
      buffer.writeln(history.transcription!.text);
      buffer.writeln();
    }

    for (final promptResult in history.promptResults) {
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('## ${promptResult.promptName}');
      buffer.writeln();
      buffer.writeln('**Prompt:**');
      buffer.writeln();
      buffer.writeln(promptResult.promptTemplate);
      buffer.writeln();
      buffer.writeln('**Ergebnis:**');
      buffer.writeln();
      buffer.writeln(promptResult.llmResponse);
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }

  @override
  String getSubject(TranscriptionHistory history) {
    final name = PathUtils.removeExtension(history.audioFileName);
    return 'VIOSA Export: $name';
  }
}
