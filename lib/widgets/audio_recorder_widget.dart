import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/audio_file.dart';
import '../services/recording_service.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

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

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  final IRecordingService _recordingService = RecordingService();
  RecordState _recordState = RecordState.stop;
  Duration _duration = Duration.zero;
  bool _hasPermission = false;
  bool _isStopping = false;

  @override
  void initState() {
    super.initState();
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
        });
      }
    });
  }

  @override
  void dispose() {
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

      await _recordingService.startRecording();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Fehler beim Starten der Aufnahme: $e');
      }
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
    setState(() {
      _isStopping = true;
    });

    try {
      final audioFile = await _recordingService.stopRecording();
      if (audioFile != null && mounted) {
        widget.onRecordingComplete(audioFile);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Fehler beim Beenden der Aufnahme: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStopping = false;
        });
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
      await _recordingService.cancelRecording();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Fehler beim Abbrechen: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              const Icon(Icons.mic_off, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Mikrofon-Berechtigung erforderlich',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bitte erteilen Sie die Berechtigung in den Einstellungen',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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
                  color: _recordState == RecordState.record ? Colors.red : null,
                ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 16),
            Text(
              _formatDuration(_duration),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
            ),
            const SizedBox(height: 16),
            if (_recordState == RecordState.stop) ...[
              FilledButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.fiber_manual_record),
                label: const Text('Aufnahme starten'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.red,
                ),
              ),
            ] else ...[
              if (_isStopping) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
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
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _cancelRecording,
                        icon: const Icon(Icons.close),
                        label: const Text('Abbrechen'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _recordState == RecordState.pause ? _resumeRecording : _pauseRecording,
                        icon: Icon(_recordState == RecordState.pause ? Icons.play_arrow : Icons.pause),
                        label: Text(_recordState == RecordState.pause ? 'Fortsetzen' : 'Pause'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _stopRecording,
                        icon: const Icon(Icons.stop),
                        label: const Text('Fertig'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: Colors.green,
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
