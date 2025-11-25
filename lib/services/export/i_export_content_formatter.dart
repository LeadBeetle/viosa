import '../../models/transcription_history.dart';

/// Interface für die Formatierung von Transkriptionsdaten für den Export.
/// Ermöglicht verschiedene Formatierungsstrategien (Plain Text, HTML, etc.)
abstract class IExportContentFormatter {
  /// Formatiert die Transkriptionshistorie in einen strukturierten String.
  String format(TranscriptionHistory history);

  /// Gibt den Betreff/Titel für den Export zurück (z.B. E-Mail-Betreff).
  String getSubject(TranscriptionHistory history);
}
