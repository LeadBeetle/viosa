import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'waveform_painter.dart';

/// Consolidated waveform display widget
/// Single Responsibility: Display audio waveform visualization with consistent styling
class WaveformDisplayWidget extends StatelessWidget {
  final List<double>? samples;
  final double height;
  final bool showLoadingState;
  final bool showEmptyState;
  final Function(double)? onTap;
  final Duration? currentPosition;
  final Duration? totalDuration;

  const WaveformDisplayWidget({
    super.key,
    this.samples,
    this.height = 120,
    this.showLoadingState = false,
    this.showEmptyState = true,
    this.onTap,
    this.currentPosition,
    this.totalDuration,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Loading state
    if (showLoadingState) {
      return Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.large),
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: AppIconSize.large,
                height: AppIconSize.large,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Waveform wird geladen...',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state (no samples)
    if (samples == null || samples!.isEmpty) {
      if (!showEmptyState) {
        return const SizedBox.shrink();
      }

      return Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.large),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.graphic_eq_rounded,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
            size: AppIconSize.xlarge,
          ),
        ),
      );
    }

    // Normal state with waveform
    final waveformWidget = Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: CustomPaint(
        painter: WaveformPainter(
          samples: samples!,
          color: colorScheme.primary,
          secondaryColor: colorScheme.secondary,
          strokeWidth: 3.5,
          currentPosition: currentPosition,
          totalDuration: totalDuration,
        ),
      ),
    );

    // If onTap is provided, make it interactive
    if (onTap != null) {
      return GestureDetector(
        onTapDown: (details) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPosition = box.globalToLocal(details.globalPosition);
          final progress = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
          onTap!(progress);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: waveformWidget,
        ),
      );
    }

    return waveformWidget;
  }
}
