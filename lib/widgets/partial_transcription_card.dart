import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../l10n/l10n.dart';

/// Weist darauf hin, dass einzelne Abschnitte nicht transkribiert werden
/// konnten, und bietet einen erneuten Versuch an.
class PartialTranscriptionCard extends StatelessWidget {
  final int failedCount;
  final bool isRetrying;
  final VoidCallback? onRetry;

  const PartialTranscriptionCard({
    super.key,
    required this.failedCount,
    this.isRetrying = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.transcriptionPartialTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        context.l10n.transcriptionPartialWarning(failedCount),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Align(
              alignment: Alignment.centerRight,
              child: isRetrying
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: AppIconSize.small,
                          width: AppIconSize.small,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          context.l10n.retryingFailedSegments,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    )
                  : FilledButton.tonalIcon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text(context.l10n.retryFailedSegments),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
