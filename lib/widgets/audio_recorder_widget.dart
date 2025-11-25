import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'waveform_display_widget.dart';
import '../models/audio_file.dart';
import '../services/recording_service.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../services/snackbar_service.dart';
import '../l10n/l10n.dart';
import 'app_loading_indicator.dart';
import 'fancy_recording_button.dart';

/// Widget for audio recording with controls
/// Follows Single Responsibility Principle: Only handles recording UI
class AudioRecorderWidget extends StatefulWidget {
  final Function(AudioFile) onRecordingComplete;
  final Function(List<double>)? onWaveformUpdate;

  const AudioRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    this.onWaveformUpdate,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> with WidgetsBindingObserver {
  final IRecordingService _recordingService = RecordingService();
  RecordState _recordState = RecordState.stop;
  bool _hasPermission = false;
  bool _isStopping = false;

  // Visualization state
  final List<double> _amplitudes = [];
  // Keep last 100 samples for visualization
  static const int _maxSamples = 100;

  // Recording duration
  Duration _currentDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
          _currentDuration = duration;
        });
      }
    });

    _recordingService.amplitudeStream.listen((amplitude) {
      if (mounted && (_recordState == RecordState.record)) {
        setState(() {
          _amplitudes.add(amplitude);
          if (_amplitudes.length > _maxSamples) {
            _amplitudes.removeAt(0);
          }
        });
        widget.onWaveformUpdate?.call(_amplitudes);
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
          title: Text(context.l10n.storagePermissionRequiredTitle),
          content: Text(context.l10n.storagePermissionRequiredContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.grantPermission),
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
          title: Text(context.l10n.permissionDeniedTitle),
          content: Text(context.l10n.permissionDeniedContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.no),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.openSettings),
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
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!_hasPermission) {
      return Card(
        elevation: AppElevation.medium,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic_off_rounded,
                  size: AppIconSize.emptyState,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Text(
                'Mikrofon-Berechtigung erforderlich',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Bitte erteilen Sie die Berechtigung in den Einstellungen',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.l),
              FilledButton.icon(
                onPressed: _checkPermission,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Erneut prüfen'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: AppElevation.medium,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusHeader(context),
            const SizedBox(height: AppSpacing.l),
            _buildTimerDisplay(context),
            const SizedBox(height: AppSpacing.l),
            _buildWaveformOrInfo(context),
            const SizedBox(height: AppSpacing.l),
            _buildControls(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    IconData icon;
    Color iconColor;
    String statusText;

    switch (_recordState) {
      case RecordState.record:
        icon = Icons.fiber_manual_record_rounded;
        iconColor = colorScheme.error;
        statusText = context.l10n.recordingInProgress;
        break;
      case RecordState.pause:
        icon = Icons.pause_circle_rounded;
        iconColor = colorScheme.primary;
        statusText = context.l10n.paused;
        break;
      default:
        icon = Icons.mic_rounded;
        iconColor = colorScheme.primary;
        statusText = context.l10n.readyToRecord;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: AppIconSize.medium,
          ),
          const SizedBox(width: AppSpacing.s),
          Text(
            statusText,
            style: textTheme.titleSmall?.copyWith(
              color: iconColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.m,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Text(
        _formatDuration(_currentDuration),
        style: textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontFeatures: [const FontFeature.tabularFigures()],
          color: colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildWaveformOrInfo(BuildContext context) {
    if (_recordState == RecordState.record || _recordState == RecordState.pause) {
      return WaveformDisplayWidget(
        samples: _amplitudes,
        height: 120,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildControls(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_recordState == RecordState.stop) {
      return Center(
        child: FancyRecordingButton(
          onPressed: _startRecording,
          isEnabled: true,
        ),
      );
    }

    if (_isStopping) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            children: [
              const AppLoadingIndicator.medium(),
              const SizedBox(height: AppSpacing.m),
              Text(
                context.l10n.savingRecording,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildControlButton(
            context: context,
            icon: Icons.close_rounded,
            label: context.l10n.cancel,
            onPressed: _cancelRecording,
            isPrimary: false,
            color: colorScheme.error,
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          flex: 3,
          child: _buildControlButton(
            context: context,
            icon: _recordState == RecordState.pause
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            label: _recordState == RecordState.pause ? context.l10n.resume : context.l10n.pause,
            onPressed: _recordState == RecordState.pause
                ? _resumeRecording
                : _pauseRecording,
            isPrimary: true,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          flex: 2,
          child: _buildControlButton(
            context: context,
            icon: Icons.check_rounded,
            label: context.l10n.done,
            onPressed: _stopRecording,
            isPrimary: true,
            color: colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: isPrimary ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.m,
            horizontal: AppSpacing.s,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: isPrimary
                ? null
                : Border.all(
                    color: color,
                    width: 2,
                  ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppIconSize.large,
                color: isPrimary ? colorScheme.onPrimary : color,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: isPrimary ? colorScheme.onPrimary : color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
