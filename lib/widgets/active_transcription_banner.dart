import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/split_transcription_provider.dart';
import '../utils/constants.dart';
import '../l10n/l10n.dart';

/// Zeigt auf der Startseite an, dass im Hintergrund eine Transkription läuft.
class ActiveTranscriptionBanner extends StatelessWidget {
  final void Function(String historyId) onOpen;

  const ActiveTranscriptionBanner({
    super.key,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SplitTranscriptionProvider>(
      builder: (context, provider, _) {
        if (!provider.isRunning) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final job = provider.currentJob;
        final fileName = provider.activeFileName ?? '';
        final percent = job?.progressPercentage ?? 0;
        final historyId = provider.activeHistoryId;

        return Card(
          margin: const EdgeInsets.fromLTRB(
            AppConstants.defaultPadding,
            AppConstants.defaultPadding,
            AppConstants.defaultPadding,
            0,
          ),
          color: theme.colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                SizedBox(
                  height: AppIconSize.medium,
                  width: AppIconSize.medium,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: job == null || job.totalSplits == 0 ? null : job.progress,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.transcriptionRunningBannerTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        context.l10n.transcriptionRunningBannerSubtitle(
                          fileName,
                          percent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                if (historyId != null)
                  TextButton(
                    onPressed: () => onOpen(historyId),
                    child: Text(context.l10n.openRunningTranscription),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
