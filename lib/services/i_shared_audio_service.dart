/// Schnittstelle für Audiodateien, die aus anderen Apps geteilt werden.
abstract class ISharedAudioService {
  /// Liefert den Pfad einer beim Start geteilten Datei, sofern vorhanden.
  Future<String?> consumeInitialSharedFile();

  /// Meldet Dateien, die während der Laufzeit geteilt werden.
  Stream<String> get sharedFiles;

  /// Gibt die Ressourcen frei.
  void dispose();
}
