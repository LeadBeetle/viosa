import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'waveform_painter.dart';

/// Compact audio player widget for collapsed/sticky state
/// Shows waveform with progress and play button in a single row
class MiniAudioPlayerWidget extends StatelessWidget {
  final List<double>? recordedAmplitudes;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const MiniAudioPlayerWidget({
    super.key,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.onPlayPause,
    this.recordedAmplitudes,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      child: Row(
        children: [
          _buildPlayButton(colorScheme),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: _buildWaveformWithProgress(context, colorScheme),
          ),
          const SizedBox(width: AppSpacing.m),
          _buildTimeDisplay(colorScheme, textTheme),
        ],
      ),
    );
  }

  Widget _buildPlayButton(ColorScheme colorScheme) {
    return Material(
      color: colorScheme.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPlayPause,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: AppIconSize.large,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildWaveformWithProgress(BuildContext context, ColorScheme colorScheme) {
    if (recordedAmplitudes == null || recordedAmplitudes!.isEmpty) {
      return _buildProgressBar(colorScheme);
    }

    return SizedBox(
      height: 36,
      child: CustomPaint(
        painter: WaveformPainter(
          samples: recordedAmplitudes!,
          color: colorScheme.primary,
          secondaryColor: colorScheme.secondary,
          strokeWidth: 2.0,
          currentPosition: position,
          totalDuration: duration,
        ),
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme colorScheme) {
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Container(
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: colorScheme.surfaceContainerHighest,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(ColorScheme colorScheme, TextTheme textTheme) {
    return Text(
      '${_formatDuration(position)} / ${_formatDuration(duration)}',
      style: textTheme.bodySmall?.copyWith(
        fontFeatures: [const FontFeature.tabularFigures()],
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
