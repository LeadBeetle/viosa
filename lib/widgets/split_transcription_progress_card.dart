import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/split_transcription_job.dart';
import '../providers/split_transcription_provider.dart';
import 'split_item_widget.dart';

/// Widget for displaying split transcription progress
/// Following Single Responsibility Principle (SRP)
class SplitTranscriptionProgressCard extends StatelessWidget {
  final SplitTranscriptionJob job;
  final VoidCallback? onCancel;
  final VoidCallback? onViewMerged;

  const SplitTranscriptionProgressCard({
    super.key,
    required this.job,
    this.onCancel,
    this.onViewMerged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),

          const Divider(height: 1),

          // Overall progress
          _buildOverallProgress(context),

          const Divider(height: 1),

          // Splits list
          _buildSplitsList(context),

          const Divider(height: 1),

          // Actions
          _buildActions(context),
        ],
      ),
    );
  }

  /// Builds the header section
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.audiotrack,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.originalFileName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Cancel button (for processing jobs)
              if (job.status == JobStatus.processing && onCancel != null)
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                  tooltip: 'Transkription abbrechen',
                  color: Colors.red,
                  iconSize: 24,
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatusChip(context),
        ],
      ),
    );
  }

  /// Builds status chip
  Widget _buildStatusChip(BuildContext context) {
    IconData icon;
    String text;
    Color color;

    switch (job.status) {
      case JobStatus.queued:
        icon = Icons.schedule;
        text = 'In Warteschlange';
        color = Colors.grey;
        break;
      case JobStatus.processing:
        icon = Icons.sync;
        text = 'Wird verarbeitet';
        color = Theme.of(context).colorScheme.primary;
        break;
      case JobStatus.completed:
        icon = Icons.check_circle;
        text = 'Abgeschlossen';
        color = Colors.green;
        break;
      case JobStatus.partialFailure:
        icon = Icons.warning;
        text = 'Teilweise fehlgeschlagen';
        color = Colors.orange;
        break;
      case JobStatus.cancelled:
        icon = Icons.cancel;
        text = 'Abgebrochen';
        color = Colors.red;
        break;
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Builds overall progress section
  Widget _buildOverallProgress(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gesamtfortschritt',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${job.completedCount}/${job.totalSplits} Segmente abgeschlossen',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: job.progress,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${job.progressPercentage}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (job.estimatedTimeRemainingText != null &&
                  job.status == JobStatus.processing)
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Noch ca. ${job.estimatedTimeRemainingText}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
            ],
          ),
          if (job.failedCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${job.failedCount} Segment(e) fehlgeschlagen',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds splits list section
  Widget _buildSplitsList(BuildContext context) {
    // Find current split being processed
    final currentSplit = job.currentSplit;

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: job.splits.length,
        itemBuilder: (context, index) {
          final split = job.splits[index];
          final isCurrentSplit = currentSplit?.id == split.id;

          return SplitItemWidget(
            split: split,
            totalSplits: job.totalSplits,
            isCurrentSplit: isCurrentSplit,
            onRetry: split.canRetry
                ? () => _handleRetrySplit(context, split.id)
                : null,
          );
        },
      ),
    );
  }

  /// Builds actions section
  Widget _buildActions(BuildContext context) {
    // Only show actions section if there's a "View Transcription" button to display
    if (!(job.isFinished && job.mergedTranscription != null && onViewMerged != null)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // View merged transcription button (for completed jobs)
          ElevatedButton.icon(
            onPressed: onViewMerged,
            icon: const Icon(Icons.visibility),
            label: const Text('Transkription anzeigen'),
          ),
        ],
      ),
    );
  }

  /// Handles retry of a failed split
  void _handleRetrySplit(BuildContext context, String splitId) async {
    final provider = Provider.of<SplitTranscriptionProvider>(context, listen: false);

    try {
      await provider.retryFailedSplit(job.id, splitId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Segment wird erneut transkribiert...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim erneuten Versuch: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
