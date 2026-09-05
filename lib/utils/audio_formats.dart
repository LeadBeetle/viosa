/// Einzige Quelle für unterstützte Audioformate und deren MIME-Typen.
///
/// Erweiterungen werden ohne führenden Punkt und in Kleinschreibung geführt.
/// M4A/MP4 werden bewusst als `audio/mpeg` ausgeliefert, weil OpenRouter
/// diesen MIME-Typ für AAC-Container erwartet.
class AudioFormats {
  static const String _fallbackMimeType = 'audio/mpeg';

  static const Map<String, String> _mimeTypesByExtension = {
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'mp4': 'audio/mpeg',
    'm4a': 'audio/mpeg',
    'aac': 'audio/aac',
    'ogg': 'audio/ogg',
    'oga': 'audio/ogg',
    'flac': 'audio/flac',
    'opus': 'audio/opus',
    'wma': 'audio/x-ms-wma',
    '3gp': 'audio/3gpp',
    'amr': 'audio/amr',
    'webm': 'audio/webm',
    'spx': 'audio/speex',
    'mid': 'audio/midi',
    'midi': 'audio/midi',
    'mka': 'audio/x-matroska',
    'ape': 'audio/ape',
    'wv': 'audio/wavpack',
    'tta': 'audio/x-tta',
    'ac3': 'audio/ac3',
    'dts': 'audio/vnd.dts',
    'alac': 'audio/alac',
    'aiff': 'audio/aiff',
    'aif': 'audio/aiff',
    'aifc': 'audio/aiff',
    'caf': 'audio/x-caf',
    'pcm': 'audio/pcm',
    'raw': 'audio/pcm',
  };

  /// Alle unterstützten Erweiterungen ohne führenden Punkt.
  static List<String> get supportedExtensions =>
      _mimeTypesByExtension.keys.toList(growable: false);

  /// Extrahiert die Erweiterung eines Datei- oder Pfadnamens ohne führenden Punkt.
  static String extensionOf(String pathOrName) {
    final separatorIndex = pathOrName.lastIndexOf(RegExp(r'[/\\]'));
    final fileName = separatorIndex >= 0
        ? pathOrName.substring(separatorIndex + 1)
        : pathOrName;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  /// Prüft, ob die Erweiterung ein unterstütztes Audioformat bezeichnet.
  static bool isSupportedExtension(String extension) =>
      _mimeTypesByExtension.containsKey(extension.toLowerCase());

  /// Prüft, ob der Pfad auf ein unterstütztes Audioformat verweist.
  static bool isSupportedPath(String pathOrName) =>
      isSupportedExtension(extensionOf(pathOrName));

  /// Liefert den MIME-Typ zur Erweiterung, sonst den Fallback `audio/mpeg`.
  static String mimeTypeForExtension(String extension) =>
      _mimeTypesByExtension[extension.toLowerCase()] ?? _fallbackMimeType;

  /// Liefert den MIME-Typ zum Pfad, sonst den Fallback `audio/mpeg`.
  static String mimeTypeForPath(String pathOrName) =>
      mimeTypeForExtension(extensionOf(pathOrName));

  AudioFormats._();
}
