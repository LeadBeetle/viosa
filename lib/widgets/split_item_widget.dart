import 'package:flutter/material.dart';
import '../models/audio_split.dart';

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
      elevation: isCurrentSplit ? 4 : 1,
      color: isCurrentSplit
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Split number and time range
            Row(
              children: [
                _buildStatusIcon(context),
                const SizedBox(width: 8),
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
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            const SizedBox(height: 8),

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
        color = Colors.grey;
        break;
      case SplitStatus.processing:
        icon = Icons.sync;
        color = Theme.of(context).colorScheme.primary;
        break;
      case SplitStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case SplitStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return split.status == SplitStatus.processing
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        : Icon(icon, color: color, size: 24);
  }

  /// Builds status badge
  Widget _buildStatusBadge(BuildContext context) {
    String text;
    Color color;

    switch (split.status) {
      case SplitStatus.pending:
        text = 'Ausstehend';
        color = Colors.grey;
        break;
      case SplitStatus.processing:
        text = 'Wird verarbeitet';
        color = Theme.of(context).colorScheme.primary;
        break;
      case SplitStatus.completed:
        text = 'Abgeschlossen';
        color = Colors.green;
        break;
      case SplitStatus.failed:
        text = 'Fehlgeschlagen';
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
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
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              'Versuch ${split.attemptCount}/3',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  wordCount != null ? '$wordCount Wörter' : 'Abgeschlossen',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
            if (split.transcriptionText != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fehlgeschlagen nach ${split.attemptCount} Versuchen',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (split.errorMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            split.errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.red.withOpacity(0.8),
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
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
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
