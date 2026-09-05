/// Einheitliche Formatierung von Dateigrößen.
///
/// Einzige Quelle für die Darstellung, damit dieselbe Datei in jedem
/// Bildschirm dieselbe Größe anzeigt.
class FileSizeFormatter {
  static const int _kilobyte = 1024;
  static const int _megabyte = 1024 * 1024;
  static const int _gigabyte = 1024 * 1024 * 1024;

  /// Formatiert Bytes menschenlesbar (B, KB, MB, GB) mit einer Nachkommastelle.
  static String format(int bytes) {
    if (bytes < _kilobyte) {
      return '$bytes B';
    }
    if (bytes < _megabyte) {
      return '${(bytes / _kilobyte).toStringAsFixed(1)} KB';
    }
    if (bytes < _gigabyte) {
      return '${(bytes / _megabyte).toStringAsFixed(1)} MB';
    }
    return '${(bytes / _gigabyte).toStringAsFixed(1)} GB';
  }

  FileSizeFormatter._();
}
