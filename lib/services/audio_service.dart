import 'dart:io';
import 'package:just_audio/just_audio.dart';

/// Interface for audio playback operations
/// Following Interface Segregation Principle (ISP)
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

/// Service for handling audio playback
/// Single Responsibility Principle (SRP): Only handles audio playback
class AudioService implements IAudioService {
  final AudioPlayer _player;
  String? _currentFilePath;

  AudioService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  @override
  Future<void> loadAudio(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist at path: $filePath');
      }

      _currentFilePath = filePath;
      await _player.setFilePath(filePath);
    } catch (e) {
      throw Exception('Failed to load audio file: $e');
    }
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      throw Exception('Failed to pause audio: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      throw Exception('Failed to seek audio: $e');
    }
  }

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  @override
  Stream<bool> get playingStream => _player.playingStream;

  @override
  String? get currentFilePath => _currentFilePath;

  @override
  void dispose() {
    _player.dispose();
  }
}
