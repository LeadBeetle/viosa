import 'package:flutter/material.dart';
import '../models/audio_split.dart';
import '../utils/constants.dart';

/// Widget for displaying a single audio split item
/// Following Single Responsibility Principle (SRP)
class SplitItemWidget extends StatelessWidget {
  final AudioSplit split;
  final int totalSplits;
  final VoidCallback? onRetry;
  final bool isCurrentSplit;

  const SplitItemWidget({
    super.key,
    required this.split,
    required this.totalSplits,
    this.onRetry,
    this.isCurrentSplit = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isCurrentSplit ? AppElevation.high : AppElevation.low,
      color: isCurrentSplit
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.s),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Split number and time range
            Row(
              children: [
                _buildStatusIcon(context),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Segment ${split.index + 1}/$totalSplits',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        split.timeRange,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: AppOpacity.secondary),
                            ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            const SizedBox(height: AppSpacing.s),

            // Status-specific content
            _buildStatusContent(context),
          ],
        ),
      ),
    );
  }

  /// Builds status icon based on split status
  Widget _buildStatusIcon(BuildContext context) {
    IconData icon;
    Color color;

    switch (split.status) {
      case SplitStatus.pending:
        icon = Icons.schedule;
        color = Theme.of(context).colorScheme.outline;
        break;
      case SplitStatus.processing:
        icon = Icons.sync;
        color = Theme.of(context).colorScheme.primary;
        break;
      case SplitStatus.completed:
        icon = Icons.check_circle;
        color = Theme.of(context).colorScheme.tertiary;
        break;
      case SplitStatus.failed:
        icon = Icons.error;
        color = Theme.of(context).colorScheme.error;
        break;
    }

    return split.status == SplitStatus.processing
        ? SizedBox(
            width: AppLoadingSize.medium,
            height: AppLoadingSize.medium,
            child: CircularProgressIndicator(
              strokeWidth: AppStrokeWidth.thin,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        : Icon(icon, color: color, size: AppIconSize.medium);
  }

  /// Builds status badge
  Widget _buildStatusBadge(BuildContext context) {
    String text;
    Color color;

    switch (split.status) {
      case SplitStatus.pending:
        text = 'Ausstehend';
        color = Theme.of(context).colorScheme.outline;
        break;
      case SplitStatus.processing:
        text = 'Wird verarbeitet';
        color = Theme.of(context).colorScheme.primary;
        break;
      case SplitStatus.completed:
        text = 'Abgeschlossen';
        color = Theme.of(context).colorScheme.tertiary;
        break;
      case SplitStatus.failed:
        text = 'Fehlgeschlagen';
        color = Theme.of(context).colorScheme.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds status-specific content
  Widget _buildStatusContent(BuildContext context) {
    switch (split.status) {
      case SplitStatus.pending:
        return const SizedBox.shrink();

      case SplitStatus.processing:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Versuch ${split.attemptCount}/3',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: AppOpacity.secondary),
                  ),
            ),
          ],
        );

      case SplitStatus.completed:
        final wordCount = split.wordCount;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.text_fields,
                  size: AppIconSize.small,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: AppOpacity.secondary),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    wordCount != null ? '$wordCount Wörter' : 'Abgeschlossen',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: AppOpacity.secondary),
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (split.transcriptionText != null) ...[
              const SizedBox(height: AppSpacing.s),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Text(
                  split.transcriptionText!.length > 100
                      ? '${split.transcriptionText!.substring(0, 100)}...'
                      : split.transcriptionText!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        );

      case SplitStatus.failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.small),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Theme.of(context).colorScheme.error,
                    size: AppIconSize.medium,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fehlgeschlagen nach ${split.attemptCount} Versuchen',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (split.errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            split.errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.s),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh, size: AppIconSize.small),
                  label: const Text('Erneut versuchen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        );
    }
  }
}
