import 'package:flutter/material.dart';

import '../models/audio_file_info.dart';
import '../utils/constants.dart';

/// Widget for displaying a single audio file in the file picker
/// Shows file name, size, and creation date
class AudioFileItem extends StatelessWidget {
  final AudioFileInfo fileInfo;
  final VoidCallback onTap;

  const AudioFileItem({
    super.key,
    required this.fileInfo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              Container(
                width: AppIconSize.xxlarge,
                height: AppIconSize.xxlarge,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Icon(
                  Icons.audio_file,
                  color: Theme.of(context).colorScheme.primary,
                  size: AppIconSize.large,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileInfo.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: AppIconSize.small,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: AppOpacity.secondary),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            fileInfo.shortFormattedDate,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: AppOpacity.secondary),
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Icon(
                          Icons.data_usage,
                          size: AppIconSize.small,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: AppOpacity.secondary),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            fileInfo.formattedSize,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: AppOpacity.secondary),
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  fileInfo.extension.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
