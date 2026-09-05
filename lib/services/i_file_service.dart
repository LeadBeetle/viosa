import 'package:flutter/material.dart';

import '../models/audio_file.dart';

/// Schnittstelle für Dateioperationen rund um Audiodateien.
abstract class IFileService {
  /// Öffnet die Dateiauswahl und liefert die gewählte Audiodatei.
  Future<AudioFile?> pickAudioFile(BuildContext context);

  /// Übernimmt eine Datei aus einem beliebigen Pfad in die App.
  ///
  /// Dateien außerhalb des App-Speichers und des konfigurierten
  /// Aufnahmeordners werden kopiert, damit sie erhalten bleiben, wenn der
  /// Nutzer das Original verschiebt oder das System den Cache leert.
  Future<AudioFile> importFile(String sourcePath, {String? displayName});

  /// Prüft, ob die hinterlegte Datei noch existiert.
  Future<AudioFile?> reloadAudioFile(AudioFile audioFile);
}
