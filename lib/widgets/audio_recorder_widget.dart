import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'waveform_painter.dart';
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

  // Visualization state
  final List<double> _amplitudes = [];
  // Keep last 100 samples for visualization
  static const int _maxSamples = 100;
  
  // Auto-disable waveform after 30 minutes to save memory
  static const Duration _waveformDisableThreshold = Duration(minutes: 30);
  bool _isWaveformDisabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();

    _checkPermission();

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

          // Auto-disable waveform after threshold to save memory on long recordings
          if (!_isWaveformDisabled && duration >= _waveformDisableThreshold) {
            _disableWaveform();
          }
        });
      }
    });

    _recordingService.amplitudeStream.listen((amplitude) {
      if (mounted && !_isWaveformDisabled && (_recordState == RecordState.record)) {
        setState(() {
          _amplitudes.add(amplitude);
          if (_amplitudes.length > _maxSamples) {
            _amplitudes.removeAt(0);
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Keep recording running in background - WakeLock and AudioSession handle this
    // Visualization automatically pauses as we stop updating state when paused/backgrounded
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingService.dispose();
    super.dispose();
  }

  /// Disables waveform visualization to save memory during long recordings
  void _disableWaveform() {
    try {
      _isWaveformDisabled = true;
      _amplitudes.clear(); // Clear data to save memory
      debugPrint('Waveform visualization disabled after $_waveformDisableThreshold to conserve memory');
    } catch (e) {
      debugPrint('Failed to disable waveform: $e');
    }
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
      
      // Clear previous amplitudes
      setState(() {
        _amplitudes.clear();
        _isWaveformDisabled = false;
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Fehler beim Starten der Aufnahme: $e');
      }
      // Cleanup visualization on error
      setState(() {
        _amplitudes.clear();
      });
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
      // Stop visualization
      setState(() {
        _isWaveformDisabled = false; // Reset for next recording
      });

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
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Fehler beim Pausieren: $e');
      }
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recordingService.resumeRecording();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Fehler beim Fortsetzen: $e');
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      // Stop visualization
      setState(() {
        _amplitudes.clear();
        _isWaveformDisabled = false;
      });

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
            // Audio waveform visualization (shows when recording or paused, unless disabled for memory)
            if ((_recordState == RecordState.record || _recordState == RecordState.pause) && !_isWaveformDisabled) ...[
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width - (AppConstants.defaultPadding * 4), 100),
                  painter: WaveformPainter(
                    samples: _amplitudes,
                    color: Theme.of(context).colorScheme.primary,
                    secondaryColor: Theme.of(context).colorScheme.secondary,
                    strokeWidth: 3.0,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
            ] else if ((_recordState == RecordState.record || _recordState == RecordState.pause) && _isWaveformDisabled) ...[
              // Show info message when waveform is disabled
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: AppIconSize.medium,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Text(
                        'Wellenform-Anzeige deaktiviert nach 30 Min zur Speicheroptimierung',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
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
