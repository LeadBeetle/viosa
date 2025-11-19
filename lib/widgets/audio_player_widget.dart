import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../services/audio_service.dart';
import '../utils/constants.dart';
import '../services/snackbar_service.dart';

/// Widget for audio playback controls
/// Follows Single Responsibility Principle: Only handles audio player UI
class AudioPlayerWidget extends StatefulWidget {
  final IAudioService audioService;
  final String fileName;
  final String filePath;

  const AudioPlayerWidget({
    super.key,
    required this.audioService,
    required this.fileName,
    required this.filePath,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  // Waveform visualization controller
  late final PlayerController _playerController;
  bool _isWaveformReady = false;

  @override
  void initState() {
    super.initState();
    _playerController = PlayerController();
    _setupListeners();
    _prepareWaveform();
  }

  Future<void> _prepareWaveform() async {
    final filePath = widget.filePath;
    try {
      await _playerController.preparePlayer(
        path: filePath,
        shouldExtractWaveform: true,
      );

      // Listen to waveform controller's onCurrentDurationChanged to sync seeking
      _playerController.onCurrentDurationChanged.listen((duration) {
        // When waveform position changes (via user seeking), sync with audio service
        final currentAudioPosition = _position.inMilliseconds;
        if ((duration - currentAudioPosition).abs() > 500) {
          // Only sync if difference is > 500ms (to avoid fighting with natural playback)
          widget.audioService.seek(Duration(milliseconds: duration));
        }
      });

      if (mounted) {
        setState(() {
          _isWaveformReady = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to prepare waveform: $e');
    }
  }

  void _setupListeners() {
    widget.audioService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });

        // Don't continuously sync waveform - it interferes with seeking
        // The waveform controller handles its own playback position
      }
    });

    widget.audioService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    });

    widget.audioService.playingStream.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
      }
    });
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await widget.audioService.pause();
        // Pause waveform animation
        if (_isWaveformReady) {
          try {
            await _playerController.pausePlayer();
          } catch (e) {
            debugPrint('Failed to pause waveform: $e');
          }
        }
      } else {
        await widget.audioService.play();
        // Start waveform animation
        if (_isWaveformReady) {
          try {
            await _playerController.startPlayer();
          } catch (e) {
            debugPrint('Failed to start waveform: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _onSeek(double value) async {
    final position = Duration(milliseconds: value.toInt());
    await widget.audioService.seek(position);

    // Sync waveform position
    if (_isWaveformReady) {
      try {
        await _playerController.seekTo(value.toInt());
      } catch (e) {
        debugPrint('Failed to seek waveform: $e');
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.headphones,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Audio Player',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Waveform visualization or fallback to slider
            if (_isWaveformReady) ...[
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                ),
                child: AudioFileWaveforms(
                  size: Size(MediaQuery.of(context).size.width - (AppConstants.defaultPadding * 4), 80),
                  playerController: _playerController,
                  enableSeekGesture: true,
                  waveformType: WaveformType.fitWidth,
                  playerWaveStyle: PlayerWaveStyle(
                    fixedWaveColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    liveWaveColor: Theme.of(context).colorScheme.primary,
                    waveCap: StrokeCap.round,
                    waveThickness: 3.0,
                    spacing: 4.0,
                    showSeekLine: true,
                    seekLineColor: Theme.of(context).colorScheme.secondary,
                    seekLineThickness: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ] else ...[
              // Fallback to slider while waveform is loading
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _position.inMilliseconds.toDouble().clamp(
                        0.0,
                        _duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                      ),
                      max: _duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                      onChanged: _onSeek,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: _togglePlayPause,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  iconSize: 32,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
