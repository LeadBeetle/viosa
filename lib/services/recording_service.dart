import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/audio_file.dart';
import 'settings_service.dart';

/// Interface for audio recording service
/// Follows Interface Segregation Principle: Only recording-related methods
abstract class IRecordingService {
  Future<void> startRecording();
  Future<AudioFile?> stopRecording();
  Future<void> pauseRecording();
  Future<void> resumeRecording();
  Future<void> cancelRecording();
  Future<bool> hasPermission();
  Stream<RecordState> get recordStateStream;
  Stream<Duration> get durationStream;
  Future<bool> isRecording();
  Future<bool> isPaused();
  void dispose();
}

/// Service for recording audio
/// Follows Single Responsibility Principle: Only handles audio recording
class RecordingService implements IRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final ISettingsService _settingsService = SettingsService();
  Timer? _timer;
  Duration _currentDuration = Duration.zero;
  String? _recordingPath;

  @override
  Stream<RecordState> get recordStateStream => _recorder.onStateChanged();

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  @override
  Future<bool> isPaused() async {
    return await _recorder.isPaused();
  }

  @override
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  @override
  Future<void> startRecording() async {
    // Check microphone permission
    if (!await hasPermission()) {
      throw Exception('Mikrofon-Berechtigung nicht erteilt');
    }

    // Get save path from settings or use default
    final customPath = await _settingsService.getAudioSavePath();
    final Directory directory;

    if (customPath != null && customPath.isNotEmpty) {
      // Custom path selected - need storage permission on Android
      if (Platform.isAndroid) {
        final hasStoragePermission = await _checkStoragePermission();
        if (!hasStoragePermission) {
          // Fall back to default directory if permission denied
          directory = await getApplicationDocumentsDirectory();
        } else {
          // Permission granted, use custom path
          directory = Directory(customPath);
          // Create directory if it doesn't exist
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        }
      } else {
        // iOS or other platforms - use custom path directly
        directory = Directory(customPath);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      }
    } else {
      // Use default application documents directory
      directory = await getApplicationDocumentsDirectory();
    }

    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _recordingPath = '${directory.path}/recording_$timestamp.m4a';

    // Start recording
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _recordingPath!,
    );

    // Start duration timer
    _currentDuration = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentDuration += const Duration(seconds: 1);
      _durationController.add(_currentDuration);
    });
  }

  @override
  Future<AudioFile?> stopRecording() async {
    _timer?.cancel();
    _timer = null;

    final path = await _recorder.stop();
    if (path == null) {
      return null;
    }

    final file = File(path);
    if (!await file.exists()) {
      return null;
    }

    // Convert to AudioFile
    final bytes = await file.readAsBytes();
    final base64Data = base64Encode(bytes);
    final size = await file.length();

    final audioFile = AudioFile(
      path: path,
      name: path.split('/').last,
      base64Data: base64Data,
      mimeType: 'audio/mp4',
      size: size,
    );

    _recordingPath = null;
    _currentDuration = Duration.zero;

    return audioFile;
  }

  @override
  Future<void> pauseRecording() async {
    await _recorder.pause();
    _timer?.cancel();
  }

  @override
  Future<void> resumeRecording() async {
    await _recorder.resume();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentDuration += const Duration(seconds: 1);
      _durationController.add(_currentDuration);
    });
  }

  @override
  Future<void> cancelRecording() async {
    _timer?.cancel();
    _timer = null;

    await _recorder.stop();

    // Delete the recording file
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _recordingPath = null;
    }

    _currentDuration = Duration.zero;
    _durationController.add(_currentDuration);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _durationController.close();
  }

  /// Check if storage permission is granted for writing to custom directories
  Future<bool> _checkStoragePermission() async {
    // Check if MANAGE_EXTERNAL_STORAGE is granted (Android 11+)
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // Check legacy storage permission (Android 6-10)
    if (await Permission.storage.isGranted) {
      return true;
    }

    return false;
  }
}
