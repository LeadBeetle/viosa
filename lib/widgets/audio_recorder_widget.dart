import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../models/audio_file.dart';
import '../services/recording_service.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../services/snackbar_service.dart';
import 'app_loading_indicator.dart';

/// Widget for audio recording with controls
/// Follows Single Responsibility Principle: Only handles recording UI
class AudioRecorderWidget extends StatefulWidget {
  final Function(AudioFile) onRecordingComplete;

  const AudioRecorderWidget({
    super.key,
    required this.onRecordingComplete,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> with WidgetsBindingObserver {
  final IRecordingService _recordingService = RecordingService();
  RecordState _recordState = RecordState.stop;
  Duration _duration = Duration.zero;
  bool _hasPermission = false;
  bool _isStopping = false;

  // Visualization controller for waveforms
  late final RecorderController _visualizationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();

    // Initialize visualization controller
    _visualizationController = RecorderController();

    _recordingService.recordStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _recordState = state;
        });
      }
    });
    _recordingService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Keep recording running in background - WakeLock and AudioSession handle this
    // We only need to handle visualization pause/resume
    if (state == AppLifecycleState.paused && _recordState == RecordState.record) {
      // App went to background while recording - pause visualization only
      try {
        _visualizationController.pause();
      } catch (e) {
        debugPrint('Visualization pause on background failed: $e');
      }
    } else if (state == AppLifecycleState.resumed && _recordState == RecordState.record) {
      // App came back to foreground while recording - resume visualization
      try {
        _visualizationController.record();
      } catch (e) {
        debugPrint('Visualization resume on foreground failed: $e');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingService.dispose();
    _visualizationController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _recordingService.hasPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _startRecording() async {
    try {
      // Check if a custom save path is configured
      final settingsProvider = context.read<SettingsProvider>();
      final customPath = settingsProvider.audioSavePath;

      // If custom path exists and we're on Android, check storage permission
      if (customPath != null && customPath.isNotEmpty && Platform.isAndroid) {
        final hasStoragePermission = await _checkAndRequestStoragePermission();
        if (!hasStoragePermission) {
          return; // User denied permission
        }
      }

      // Start the actual recording service FIRST
      await _recordingService.startRecording();

      // Then start visualization controller (may fail on some devices)
      try {
        await _visualizationController.record();
        debugPrint('Visualization controller started successfully');
      } catch (e) {
        // Visualization failure shouldn't stop the recording
        debugPrint('Visualization recording failed: $e');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Fehler beim Starten der Aufnahme: $e');
      }
      // Cleanup visualization on error
      try {
        await _visualizationController.stop();
      } catch (_) {}
    }
  }

  /// Check and request storage permission with user-friendly dialog
  Future<bool> _checkAndRequestStoragePermission() async {
    // Check if already granted
    if (await Permission.manageExternalStorage.isGranted ||
        await Permission.storage.isGranted) {
      return true;
    }

    // Show explanation dialog first
    if (mounted) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Speicherberechtigung erforderlich'),
          content: const Text(
            'Um Aufnahmen in Ihrem ausgewählten Ordner zu speichern, benötigt VIOSA Zugriff auf den Speicher.\n\n'
            'Bitte erlauben Sie den Zugriff.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Berechtigung erteilen'),
            ),
          ],
        ),
      );

      if (shouldRequest != true) {
        return false;
      }
    }

    // Request permission
    final status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      return true;
    }

    // Try legacy permission for older Android
    final legacyStatus = await Permission.storage.request();
    if (legacyStatus.isGranted) {
      return true;
    }

    // If denied, show dialog to open settings
    if (mounted && (status.isPermanentlyDenied || legacyStatus.isPermanentlyDenied)) {
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Berechtigung verweigert'),
          content: const Text(
            'Um in Ihrem gewählten Ordner zu speichern, muss die Speicherberechtigung aktiviert werden.\n\n'
            'Möchten Sie die Einstellungen öffnen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Nein'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Einstellungen öffnen'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await openAppSettings();
      }
    } else if (mounted) {
      // Permission denied but not permanently
      _showErrorSnackBar('Speicherberechtigung wurde verweigert. Die Aufnahme wird im Standard-Ordner gespeichert.');
      // Allow recording to default location
      return false;
    }

    return false;
  }

  Future<void> _stopRecording() async {
    if (_isStopping) return;

    setState(() {
      _isStopping = true;
    });

    try {
      // Stop visualization controller first (cleanup)
      try {
        await _visualizationController.stop();
      } catch (e) {
        debugPrint('Visualization stop failed: $e');
      }

      // Stop the actual recording service
      final audioFile = await _recordingService.stopRecording();

      if (audioFile != null && mounted) {
        widget.onRecordingComplete(audioFile);
      } else if (audioFile == null && mounted) {
        _showErrorSnackBar('Fehler: Aufnahme konnte nicht gespeichert werden');
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      if (mounted) {
        _showErrorSnackBar('Fehler beim Beenden der Aufnahme: $e');
      }
    } finally {
      // Always reset state, even if not mounted
      if (mounted) {
        setState(() {
          _isStopping = false;
        });
      } else {
        _isStopping = false;
      }
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _recordingService.pauseRecording();

      // Pause visualization as well
      try {
        await _visualizationController.pause();
      } catch (e) {
        debugPrint('Visualization pause failed: $e');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Fehler beim Pausieren: $e');
      }
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recordingService.resumeRecording();

      // Resume visualization as well
      try {
        await _visualizationController.record();
      } catch (e) {
        debugPrint('Visualization resume failed: $e');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Fehler beim Fortsetzen: $e');
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      // Stop visualization controller
      try {
        await _visualizationController.stop();
      } catch (e) {
        debugPrint('Visualization stop failed: $e');
      }

      await _recordingService.cancelRecording();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Fehler beim Abbrechen: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    SnackBarService().showError(context, message);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              Icon(
                Icons.mic_off,
                size: AppIconSize.xxlarge,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.m),
              const Text(
                'Mikrofon-Berechtigung erforderlich',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.s),
              const Text(
                'Bitte erteilen Sie die Berechtigung in den Einstellungen',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.m),
              ElevatedButton(
                onPressed: _checkPermission,
                child: const Text('Erneut prüfen'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _recordState == RecordState.record ? Icons.fiber_manual_record : Icons.mic,
                  color: _recordState == RecordState.record ? Theme.of(context).colorScheme.error : null,
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  _recordState == RecordState.record
                      ? 'Aufnahme läuft'
                      : _recordState == RecordState.pause
                          ? 'Pausiert'
                          : 'Bereit zur Aufnahme',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              _formatDuration(_duration),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
            ),
            const SizedBox(height: AppSpacing.m),
            // Audio waveform visualization (shows when recording or paused)
            if (_recordState == RecordState.record || _recordState == RecordState.pause) ...[
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: AudioWaveforms(
                  size: Size(MediaQuery.of(context).size.width - (AppConstants.defaultPadding * 4), 100),
                  recorderController: _visualizationController,
                  waveStyle: WaveStyle(
                    gradient: ui.Gradient.linear(
                      const Offset(0, 50),
                      Offset(MediaQuery.of(context).size.width, 50),
                      [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    showMiddleLine: false,
                    extendWaveform: true,
                    waveThickness: AppStrokeWidth.normal,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
            ],
            if (_recordState == RecordState.stop) ...[
              FilledButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.fiber_manual_record),
                label: const Text('Aufnahme starten'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ] else ...[
              if (_isStopping) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      children: const [
                        AppLoadingIndicator.medium(),
                        SizedBox(height: AppSpacing.s),
                        Text(
                          'Aufnahme wird gespeichert...',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: IconButton.outlined(
                        onPressed: _cancelRecording,
                        icon: const Icon(Icons.close),
                        tooltip: 'Abbrechen',
                        iconSize: AppIconSize.large,
                        padding: const EdgeInsets.all(AppSpacing.s),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: IconButton.filled(
                        onPressed: _recordState == RecordState.pause ? _resumeRecording : _pauseRecording,
                        icon: Icon(_recordState == RecordState.pause ? Icons.play_arrow : Icons.pause),
                        tooltip: _recordState == RecordState.pause ? 'Fortsetzen' : 'Pause',
                        iconSize: AppIconSize.large,
                        padding: const EdgeInsets.all(AppSpacing.s),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: IconButton.filled(
                        onPressed: _stopRecording,
                        icon: const Icon(Icons.check),
                        tooltip: 'Fertig',
                        iconSize: AppIconSize.large,
                        padding: const EdgeInsets.all(AppSpacing.s),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
