import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../utils/constants.dart';

/// Shows that the audio is being transcribed and offers to cancel
class TranscriptionProgressCard extends StatelessWidget {
  final String fileName;
  final VoidCallback? onCancel;

  const TranscriptionProgressCard({
    super.key,
    required this.fileName,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: AppElevation.high,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.audiotrack, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    fileName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onCancel != null)
                  IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close),
                    tooltip: context.l10n.cancelTranscription,
                    color: theme.colorScheme.error,
                    iconSize: AppIconSize.medium,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.m),
            Text(
              context.l10n.transcriptionRunningBannerTitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.transcriptionContinuesInBackground,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
