import 'package:just_audio/just_audio.dart';

/// Schnittstelle für die Audiowiedergabe.
abstract class IAudioService {
  Future<void> loadAudio(String filePath);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<PlayerState> get playerStateStream;
  Stream<bool> get playingStream;
  String? get currentFilePath;
  void dispose();
}
