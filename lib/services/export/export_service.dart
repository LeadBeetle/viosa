import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/transcription_history.dart';
import '../../utils/path_utils.dart';
import 'i_export_content_formatter.dart';
import 'plain_text_export_formatter.dart';
import 'srt_export_formatter.dart';

/// Verfügbare Exportformate.
enum ExportFormat {
  /// Transkript, Prompt-Ergebnisse und Metadaten als Markdown
  markdown,

  /// Zeitmarken als SRT-Untertiteldatei
  subtitles,
}

abstract class IExportService {
  Future<void> share(
    TranscriptionHistory history, {
    ExportFormat format = ExportFormat.markdown,
  });
}

/// Service zum Exportieren von Transkriptionen.
/// Nutzt das native System-Share-Sheet für maximale Flexibilität.
class ExportService implements IExportService {
  final IExportContentFormatter _markdownFormatter;
  final IExportContentFormatter _subtitleFormatter;

  ExportService({
    IExportContentFormatter? formatter,
    IExportContentFormatter? subtitleFormatter,
  })  : _markdownFormatter = formatter ?? PlainTextExportFormatter(),
        _subtitleFormatter = subtitleFormatter ?? SrtExportFormatter();

  @override
  Future<void> share(
    TranscriptionHistory history, {
    ExportFormat format = ExportFormat.markdown,
  }) async {
    final formatter =
        format == ExportFormat.subtitles ? _subtitleFormatter : _markdownFormatter;
    final content = formatter.format(history);
    final subject = formatter.getSubject(history);
    final baseName = PathUtils.removeExtension(history.audioFileName);
    final extension = format == ExportFormat.subtitles ? 'srt' : 'md';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$baseName.$extension');
    await file.writeAsString(content);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: subject,
      ),
    );
  }
}
