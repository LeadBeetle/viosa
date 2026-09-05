/// Formatiert Zeitdauern für Anzeige und Export.
class DurationFormatter {
  /// Liefert eine Position als `m:ss` bzw. `h:mm:ss`.
  static String position(Duration position) {
    final hours = position.inHours;
    final minutes = position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// Liefert einen SRT-Zeitstempel im Format `hh:mm:ss,mmm`.
  static String srtTimeCode(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis =
        duration.inMilliseconds.remainder(1000).toString().padLeft(3, '0');

    return '$hours:$minutes:$seconds,$millis';
  }

  DurationFormatter._();
}
