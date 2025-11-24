import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../utils/constants.dart';
import '../services/snackbar_service.dart';
import 'waveform_display_widget.dart';

/// Widget for audio playback controls
/// Follows Single Responsibility Principle: Only handles audio player UI
class AudioPlayerWidget extends StatefulWidget {
  final IAudioService audioService;
  final String fileName;
  final String filePath;
  final bool isCollapsible;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final List<double>? recordedAmplitudes;

  const AudioPlayerWidget({
    super.key,
    required this.audioService,
    required this.fileName,
    required this.filePath,
    this.isCollapsible = false,
    this.initiallyExpanded = true,
    this.onExpansionChanged,
    this.recordedAmplitudes,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
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
    super.dispose();
  }

  Widget _buildPlayerContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Waveform visualization
        _buildWaveformSection(context),
        const SizedBox(height: AppSpacing.m),
        // Timer display
        _buildTimerSection(context),
        const SizedBox(height: AppSpacing.m),
        // Playback controls
        _buildPlaybackControls(context),
      ],
    );
  }

  Widget _buildWaveformSection(BuildContext context) {
    return WaveformDisplayWidget(
      samples: widget.recordedAmplitudes,
      height: 120,
      showEmptyState: true,
      onTap: (progress) async {
        if (_duration.inMilliseconds > 0) {
          final seekPosition = Duration(
            milliseconds: (_duration.inMilliseconds * progress).round(),
          );
          await widget.audioService.seek(seekPosition);
        }
      },
      currentPosition: _position,
      totalDuration: _duration,
    );
  }

  Widget _buildTimerSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDuration(_position),
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: [const FontFeature.tabularFigures()],
              color: colorScheme.primary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Icon(
              _isPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
              size: AppIconSize.medium,
              color: colorScheme.primary,
            ),
          ),
          Text(
            _formatDuration(_duration),
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: [const FontFeature.tabularFigures()],
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _togglePlayPause,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: AppIconSize.xlarge + 8,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.isCollapsible) {
      return Card(
        elevation: AppElevation.medium,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Icon(
                    Icons.headphones_rounded,
                    size: AppIconSize.medium,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Text(
                  'Audio Player',
                  style: textTheme.titleMedium?.copyWith(
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
                  AppSpacing.l,
                  0,
                  AppSpacing.l,
                  AppSpacing.l,
                ),
                child: _buildPlayerContent(context),
              ),
            ],
          ),
        ),
      );
    }

    // Non-collapsible version with modern design
    return Card(
      elevation: AppElevation.medium,
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.l),
            _buildPlayerContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.headphones_rounded,
            color: colorScheme.primary,
            size: AppIconSize.medium,
          ),
          const SizedBox(width: AppSpacing.s),
          Text(
            'Audio Player',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
