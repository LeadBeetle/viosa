import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/audio_file.dart';
import '../utils/audio_config.dart';
import 'settings_service.dart';
import 'recording_notification_service.dart';
import 'recording_checkpoint_service.dart';

/// Interface for audio recording service
/// Follows Interface Segregation Principle: Only recording-related methods
abstract class IRecordingService {
  Future<void> startRecording();
  Future<AudioFile?> stopRecording({String? customName});
  Future<void> pauseRecording();
  Future<void> resumeRecording();
  Future<void> cancelRecording();
  Future<bool> hasPermission();
  Stream<RecordState> get recordStateStream;
  Stream<Duration> get durationStream;
  Future<bool> isRecording();
  Future<bool> isPaused();
  Stream<double> get amplitudeStream;
  void dispose();
}

/// Service for recording audio
/// Follows Single Responsibility Principle: Only handles audio recording
class RecordingService implements IRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();
  final ISettingsService _settingsService = SettingsService();
  final RecordingNotificationService _notificationService = RecordingNotificationService();
  final RecordingCheckpointService _checkpointService = RecordingCheckpointService();
  Timer? _timer;
  Timer? _checkpointTimer;
  Timer? _amplitudeTimer;
  Duration _currentDuration = Duration.zero;
  String? _recordingPath;

  // Auto-checkpoint interval (10 minutes)
  static const Duration _checkpointInterval = Duration(minutes: 10);

  @override
  Stream<RecordState> get recordStateStream => _recorder.onStateChanged();

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

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

    // Configure audio session for background recording
    await _configureAudioSession();

    // Enable wakelock to prevent device sleep during recording
    await WakelockPlus.enable();

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

    // Generate unique filename with .m4a extension (actual recording format)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _recordingPath = '${directory.path}/recording_$timestamp.m4a';

    // Start recording
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: AudioConfig.bitRate,
        sampleRate: AudioConfig.sampleRate,
      ),
      path: _recordingPath!,
    );

    // Start duration timer
    _currentDuration = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentDuration += const Duration(seconds: 1);
      _durationController.add(_currentDuration);
    });

    // Start amplitude timer (every 100ms for smooth visualization)
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      try {
        final amplitude = await _recorder.getAmplitude();
        // Normalize amplitude to 0.0 - 1.0 range
        // Typical max amplitude is around -160dB to 0dB
        // We'll map -60dB (silence) to 0.0 and 0dB (loud) to 1.0
        final current = amplitude.current;
        final normalized = ((current + 60) / 60).clamp(0.0, 1.0);
        _amplitudeController.add(normalized);
      } catch (e) {
        // Ignore errors fetching amplitude
      }
    });

    // Start checkpoint timer for crash recovery (every 10 minutes)
    _checkpointTimer = Timer.periodic(_checkpointInterval, (timer) {
      _saveCheckpoint();
    });

    // Show recording notification in status bar
    await _notificationService.showRecordingNotification();
  }

  /// Saves a checkpoint for crash recovery
  Future<void> _saveCheckpoint() async {
    if (_recordingPath != null) {
      await _checkpointService.saveCheckpoint(
        recordingPath: _recordingPath!,
        currentDuration: _currentDuration,
      );
    }
  }

  /// Configure audio session for background recording
  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker |
          AVAudioSessionCategoryOptions.allowBluetooth |
          AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: false,
    ));
    await session.setActive(true);
  }

  @override
  Future<AudioFile?> stopRecording({String? customName}) async {
    try {
      _timer?.cancel();
      _timer = null;
      _checkpointTimer?.cancel();
      _checkpointTimer = null;
      _amplitudeTimer?.cancel();
      _amplitudeTimer = null;

      final path = await _recorder.stop();

      if (path == null) {
        return null;
      }

      final file = File(path);
      if (!await file.exists()) {
        return null;
      }

      // Get file metadata without loading into memory
      final size = await file.length();

      // Use custom name if provided, otherwise generate a user-friendly name
      final String displayName;
      if (customName != null && customName.isNotEmpty) {
        displayName = '$customName.m4a';
      } else {
        // Generate user-friendly name with date/time
        final now = DateTime.now();
        final formattedDate = '${now.day.toString().padLeft(2, '0')}.'
            '${now.month.toString().padLeft(2, '0')}.'
            '${now.year} '
            '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}';
        displayName = 'Aufnahme $formattedDate.m4a';
      }

      final audioFile = AudioFile(
        path: path,
        name: displayName,
        base64Data: null, // Lazy-loaded when needed for transcription
        mimeType: 'audio/mp4', // M4A MIME type (will be converted to MP3 before transcription)
        size: size,
      );

      _recordingPath = null;
      _currentDuration = Duration.zero;

      // Clear checkpoint after successful recording
      await _checkpointService.clearCheckpoint();

      return audioFile;
    } catch (e) {
      debugPrint('Error in stopRecording: $e');
      rethrow;
    } finally {
      // Always cleanup notification, wakelock and audio session
      try {
        await WakelockPlus.disable();
      } catch (e) {
        debugPrint('Error disabling wakelock: $e');
      }

      try {
        await _deactivateAudioSession();
      } catch (e) {
        debugPrint('Error deactivating audio session: $e');
      }

      try {
        await _notificationService.cancelRecordingNotification();
      } catch (e) {
        debugPrint('Error canceling notification: $e');
      }
    }
  }

  /// Deactivate audio session when recording stops
  Future<void> _deactivateAudioSession() async {
    final session = await AudioSession.instance;
    await session.setActive(false);
  }

  @override
  Future<void> pauseRecording() async {
    await _recorder.pause();
    _timer?.cancel();
    _checkpointTimer?.cancel();
    _amplitudeTimer?.cancel();

    // Save checkpoint when pausing
    await _saveCheckpoint();

    // Update notification to show paused state
    await _notificationService.showPausedNotification();
  }

  @override
  Future<void> resumeRecording() async {
    await _recorder.resume();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentDuration += const Duration(seconds: 1);
      _durationController.add(_currentDuration);
    });

    // Restart amplitude timer
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      try {
        final amplitude = await _recorder.getAmplitude();
        final current = amplitude.current;
        final normalized = ((current + 60) / 60).clamp(0.0, 1.0);
        _amplitudeController.add(normalized);
      } catch (e) {
        // Ignore errors
      }
    });

    // Restart checkpoint timer
    _checkpointTimer = Timer.periodic(_checkpointInterval, (timer) {
      _saveCheckpoint();
    });

    // Update notification to show recording state
    await _notificationService.showRecordingNotification();
  }

  @override
  Future<void> cancelRecording() async {
    _timer?.cancel();
    _timer = null;
    _checkpointTimer?.cancel();
    _checkpointTimer = null;
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;

    await _recorder.stop();

    // Disable wakelock and deactivate audio session
    await WakelockPlus.disable();
    await _deactivateAudioSession();

    // Cancel recording notification
    await _notificationService.cancelRecordingNotification();

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

    // Clear checkpoint after cancellation
    await _checkpointService.clearCheckpoint();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _checkpointTimer?.cancel();
    _amplitudeTimer?.cancel();
    _recorder.dispose();
    _durationController.close();
    _amplitudeController.close();
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
