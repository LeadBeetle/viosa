import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/transcription_history.dart';
import 'i_export_content_formatter.dart';
import 'plain_text_export_formatter.dart';

/// Service zum Exportieren von Transkriptionen.
/// Nutzt das native System-Share-Sheet für maximale Flexibilität.
class ExportService implements IExportService {
  final IExportContentFormatter _formatter;

  ExportService({
    IExportContentFormatter? formatter,
  }) : _formatter = formatter ?? PlainTextExportFormatter();

  String _removeFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0) {
      return fileName.substring(0, lastDot);
    }
    return fileName;
  }

  @override
  Future<void> share(TranscriptionHistory history) async {
    final content = _formatter.format(history);
    final subject = _formatter.getSubject(history);
    final baseName = _removeFileExtension(history.audioFileName);

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$baseName.md');
      await file.writeAsString(content);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: subject,
        ),
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
    }
  }
}

abstract class IExportService {
  Future<void> share(TranscriptionHistory history);
}
