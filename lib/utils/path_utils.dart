import 'dart:io';

/// Hilfsfunktionen für den Vergleich und die Bereinigung von Pfaden.
class PathUtils {
  static final RegExp _trailingSeparators = RegExp(r'[/\\]+$');
  static final RegExp _invalidFileNameChars = RegExp(r'[<>:"/\\|?*]');

  /// Normalisiert einen Pfad für den Vergleich.
  ///
  /// Entfernt abschließende Trenner, vereinheitlicht Backslashes und
  /// berücksichtigt die Groß-/Kleinschreibungsunabhängigkeit unter Windows.
  static String normalize(String path) {
    String normalized = path.replaceAll(_trailingSeparators, '');
    if (Platform.isWindows) {
      normalized = normalized.toLowerCase();
    }
    return normalized.replaceAll('\\', '/');
  }

  /// Ersetzt Zeichen, die in Dateinamen nicht zulässig sind, durch Unterstriche.
  static String sanitizeFileName(String fileName) =>
      fileName.replaceAll(_invalidFileNameChars, '_');

  /// Liefert den Dateinamen eines Pfads unabhängig vom Trennzeichen.
  static String fileNameOf(String path) {
    final separatorIndex = path.lastIndexOf(RegExp(r'[/\\]'));
    return separatorIndex >= 0 ? path.substring(separatorIndex + 1) : path;
  }

  /// Entfernt die Dateiendung eines Dateinamens.
  static String removeExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0) {
      return fileName.substring(0, lastDot);
    }
    return fileName;
  }

  PathUtils._();
}
