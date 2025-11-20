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
  final bool isCollapsible;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  const AudioPlayerWidget({
    super.key,
    required this.audioService,
    required this.fileName,
    required this.filePath,
    this.isCollapsible = false,
    this.initiallyExpanded = true,
    this.onExpansionChanged,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  // Waveform visualization controller
  late PlayerController _playerController;
  bool _isWaveformReady = false;

  // Flag to prevent feedback loop when seeking
  bool _isSeeking = false;

  @override
  void initState() {
    super.initState();
    _playerController = PlayerController();
    _setupListeners();
    _prepareWaveform();
  }

  @override
  void didUpdateWidget(AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-prepare waveform if file path changed
    if (oldWidget.filePath != widget.filePath) {
      _isWaveformReady = false;
      _playerController.dispose();
      _playerController = PlayerController();
      _prepareWaveform();
    }
  }

  Future<void> _prepareWaveform() async {
    final filePath = widget.filePath;
    try {
      await _playerController.preparePlayer(
        path: filePath,
        shouldExtractWaveform: true,
      );

      // Listen to waveform controller's onCurrentDurationChanged to sync seeking
      _playerController.onCurrentDurationChanged.listen((waveformPosition) {
        // Prevent feedback loop
        if (_isSeeking) return;

        // Use waveform position directly - it's already in milliseconds
        // The PlayerController's position should match the actual audio duration
        final currentAudioPosition = _position.inMilliseconds;
        if ((waveformPosition - currentAudioPosition).abs() > 500) {
          // Only sync if difference is > 500ms (to avoid fighting with natural playback)
          _isSeeking = true;
          widget.audioService.seek(Duration(milliseconds: waveformPosition)).then((_) {
            if (mounted) {
              _isSeeking = false;
            }
          });
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
        // Don't sync waveform position - let it just be a static visualization
        // The timer below shows the actual position
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
      } else {
        await widget.audioService.play();
      }
    } catch (e) {
      if (mounted) {
        SnackBarService().showError(context, 'Error: $e');
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

  Widget _buildPlayerContent(BuildContext context) {
    return Column(
      children: [
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
              continuousWaveform: true,
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
          const SizedBox(height: AppSpacing.s),
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
        const SizedBox(height: AppSpacing.s),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              onPressed: _togglePlayPause,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: AppIconSize.xlarge,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCollapsible) {
      return Card(
        elevation: AppElevation.medium,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Row(
              children: [
                Icon(
                  Icons.headphones,
                  size: AppIconSize.medium,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  'Audio Player',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            initiallyExpanded: widget.initiallyExpanded,
            onExpansionChanged: widget.onExpansionChanged,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.defaultPadding,
                  0,
                  AppConstants.defaultPadding,
                  AppConstants.defaultPadding,
                ),
                child: _buildPlayerContent(context),
              ),
            ],
          ),
        ),
      );
    }

    // Non-collapsible version (original design)
    return Card(
      elevation: AppElevation.medium,
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
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    'Audio Player',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            _buildPlayerContent(context),
          ],
        ),
      ),
    );
  }
}
