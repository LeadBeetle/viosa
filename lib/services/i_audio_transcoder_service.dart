/// Wandelt Audiodateien in das Format um, das die Transkriptions-API annimmt
abstract class IAudioTranscoderService {
  /// Gibt an, ob [audioPath] vor dem Upload umgewandelt werden muss
  bool needsTranscoding(String audioPath);

  /// Liefert den Pfad einer WAV-Fassung von [audioPath]
  ///
  /// Ist die Datei bereits WAV, wird der Originalpfad zurückgegeben
  Future<String> toWav(String audioPath);
}
